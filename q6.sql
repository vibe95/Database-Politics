SET SEARCH_PATH TO parlgov;
drop table if exists q6 cascade;

-- You must not change this table definition.

CREATE TABLE q6(
countryId INT,
partyName VARCHAR(10),
number INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS cons_wins CASCADE;
DROP VIEW IF EXISTS country_maxs CASCADE;
DROP VIEW IF EXISTS longest_winning_streak CASCADE;

--get election winners
create view election_winners as
  select election.id as election_id , cabinet_party.party_id, election.country_id, e_date
    from election join cabinet
        on election.id = cabinet.election_id
      join cabinet_party
        on cabinet.id = cabinet_party.cabinet_id
    where cabinet_party . pm = true;


--partion winners by country then party. then order by election date. then use row_number function
--to reset row count when ever the (country,party) change
create view cons_wins as
  select *, ROW_NUMBER() OVER (PARTITION BY country_id, party_id ORDER BY e_date ASC) as ROWNUM
    from election_winners;

--group by country then get the max row number, max same (country,party) in a row
create view country_maxs as
  select country_id, MAX(ROWNUM) as max_streak
    from cons_wins
    group by country_id;

--get other details for the maxs of each country. 
create view longest_winning_streak as
  select country_maxs.country_id as countryId, party.name_short as partyName, ROWNUM as number
    from country_maxs join cons_wins
      on country_maxs.country_id = cons_wins.country_id
      and country_maxs.max_streak = cons_wins.ROWNUM
    join party
      on party.id = cons_wins.party_id;

-- the answer to the query
insert into q6 select * from longest_winning_streak;
