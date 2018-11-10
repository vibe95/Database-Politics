SET SEARCH_PATH TO parlgov;
drop table if exists q5 cascade;

-- You must not change this table definition.

CREATE TABLE q5(
electionId INT,
countryName VARCHAR(50),
winningParty VARCHAR(100),
closeRunnerUp VARCHAR(100)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS noNUll_election_results CASCADE;
DROP VIEW IF EXISTS alliance_votes CASCADE;
DROP VIEW IF EXISTS winner_alliances_votes CASCADE;
DROP VIEW IF EXISTS close_calls CASCADE;

--get election winners
create view election_winners as
  select election.id as election_id , cabinet_party.party_id, election.country_id
    from election join cabinet
        on election.id = cabinet.election_id
      join cabinet_party
        on cabinet.id = cabinet_party.cabinet_id
    where cabinet_party . pm = true;


--for heads of alliances make their alliance_id them seleves. eaiser to do group by fors later. Also get part names
create view noNUll_election_results as
  select election_result.id,election_id,party_id, party.name as party_name, votes,
        CASE WHEN alliance_id IS NULL THEN election_result.id ELSE alliance_id end as alliance_id
    from election_result join party
      on election_result.party_id = party.id;

--get all alliances with sum of votes
create view alliance_votes as
  select alliance_id, SUM(votes) as total_votes,election_id
    from noNUll_election_results
    group by alliance_id,election_id;

--get the head party name for alliance with total alliance votes
create view alliance_party_votes as
  select alliance_votes.alliance_id, party_name, alliance_votes.election_id, total_votes
    from noNUll_election_results join alliance_votes
      on noNUll_election_results.election_id = alliance_votes.election_id
      and noNUll_election_results.alliance_id = alliance_votes.alliance_id;

--get winner's total votes
create view winner_alliances_votes as
 select alliance_votes.alliance_id, total_votes, election_winners.election_id, election_winners.country_id, noNUll_election_results.party_name
   from election_winners join noNUll_election_results
      on noNUll_election_results.party_id = election_winners.party_id
      and noNUll_election_results.election_id = election_winners.election_id
  join alliance_votes
     on noNUll_election_results.id = alliance_votes.alliance_id;

--fins close calls
create view close_calls as
  select DISTINCT winner_alliances_votes.election_id as electionId, country.name as countryName,
         winner_alliances_votes.party_name as winningParty, alliance_party_votes.party_name as closeRunnerUp
    from winner_alliances_votes join alliance_party_votes
      on winner_alliances_votes.election_id = alliance_party_votes.election_id   --get all other results for this election
      and winner_alliances_votes.alliance_id != alliance_party_votes.alliance_id -- dont compare winner with them seleves
    join country
      on winner_alliances_votes.country_id = country.id
    where CAST(alliance_party_votes.total_votes as float)/winner_alliances_votes.total_votes > 0.9; --finds votes with in 10%




-- the answer to the query
insert into q5 select * from close_calls;
