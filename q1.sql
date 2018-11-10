SET SEARCH_PATH TO parlgov;
drop table if exists q1 cascade;

-- You must not change this table definition.

create table q1(
century VARCHAR(2),
country VARCHAR(50),
left_right REAL,
state_market REAL,
liberty_authority REAL
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS election_winners_centuries CASCADE;
DROP VIEW IF EXISTS noNUll_election_results CASCADE;
DROP VIEW IF EXISTS alliance_avgs CASCADE;
DROP VIEW IF EXISTS winning_avgs CASCADE;


-- Define views for your intermediate steps here.
--get all the winning parties with the century & country of election
create view election_winners_centuries as
  select election.id as election_id , cabinet_party.party_id, extract(CENTURY from election.e_date) as election_century, election.country_id
    from election join cabinet
        on election.id = cabinet.election_id
      join cabinet_party
        on cabinet.id = cabinet_party.cabinet_id
    where cabinet_party.pm = true;


--for heads of alliances make their alliance_id them seleves. eaiser to do group by for avg later
create view noNUll_election_results as
  select id,election_id,party_id, CASE WHEN alliance_id IS NULL THEN id ELSE alliance_id end as alliance_id
    from election_result;

--get avearges for all alliances
create view alliance_avgs as
  select alliance_id, AVG(left_right) as left_right_avg, AVG(state_market) as market_avg, AVG(liberty_authority) as authority_avg
    from noNUll_election_results join party_position
      on noNUll_election_results.party_id = party_position.party_id
    group by (alliance_id);

--only keep winning alliances, and get avgs for century/country
create view winning_avgs as
  select election_century as century, country.name as country, AVG(left_right_avg) as left_right, AVG(market_avg) as state_market, AVG(authority_avg) as liberty_authority
    from  election_winners_centuries join election_result
      on election_winners_centuries.election_id =  election_result.election_id   --get right results
    join alliance_avgs
      on election_result.id = alliance_avgs.alliance_id     --get the winning alliance for an election
    join country
      on election_winners_centuries.country_id = country.id
    where election_century = '20' or election_century = '21'
    group by country.name, election_century;



-- the answer to the query election_winners_centuries
insert into q1 select * from winning_avgs;
