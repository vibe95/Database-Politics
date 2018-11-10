SET SEARCH_PATH TO parlgov;
drop table if exists q2 cascade;

-- You must not change this table definition.

create table q2(
country VARCHAR(50),
electoral_system VARCHAR(100),
single_party INT,
two_to_three INT,
four_to_five INT,
six_or_more INT
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS parliamentary_election_winners CASCADE;
DROP VIEW IF EXISTS noNUll_election_results CASCADE;
DROP VIEW IF EXISTS alliance_counts CASCADE;
DROP VIEW IF EXISTS alliance_categories CASCADE;

-- Define views for your intermediate steps here.
--get all the winning parties with the of election
create view parliamentary_election_winners as
  select election.id as election_id , cabinet_party.party_id, election.country_id
    from election join cabinet
        on election.id = cabinet.election_id
        and election.e_type = 'Parliamentary election' --making sure its is parliamentary only as requested in the question
      join cabinet_party
        on cabinet.id = cabinet_party.cabinet_id
    where cabinet_party . pm = true;


--for heads of alliances make their alliance_id them seleves. eaiser to do group by later
create view noNUll_election_results as
  select id,election_id,party_id, CASE WHEN alliance_id IS NULL THEN id ELSE alliance_id end as alliance_id
    from election_result;

--get size of alliances, by setting 1 in the relvant column depending on their alliance size
create view alliance_counts as
  select alliance_id,
      CASE WHEN COUNT(alliance_id) = 1 THEN 1 ELSE NULL end as single_party,
      CASE WHEN COUNT(alliance_id) = 2 or COUNT(alliance_id) = 3 THEN 1 ELSE NULL end as two_to_three,
      CASE WHEN COUNT(alliance_id) = 4 or COUNT(alliance_id) = 5 THEN 1 ELSE NULL end as four_to_five,
      CASE WHEN COUNT(alliance_id) >= 6 THEN 1 ELSE NULL end as six_or_more
    from noNUll_election_results
    group by (alliance_id);

--for winning alliances calclate the total for each size column and group by name then system
create view alliance_categories as
  select country.name as country, country.electoral_system as electoral_system, COUNT(single_party) as single_party,
        COUNT(two_to_three) as two_to_three, COUNT(four_to_five) as four_to_five, COUNT(six_or_more) as six_or_more
    from parliamentary_election_winners join noNUll_election_results
      on parliamentary_election_winners.election_id = noNUll_election_results.election_id --get right election
    join alliance_counts
      on noNUll_election_results.id = alliance_counts.alliance_id --get allainces
    join country
      on parliamentary_election_winners.country_id = country.id
    group by country.name, country.electoral_system;  --just in case electoral_system changed in country


-- the answer to the query
insert into q2 select * from alliance_categories;
