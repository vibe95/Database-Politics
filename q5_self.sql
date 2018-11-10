-- Scenario: 1 parliamentary election, 2 parties with vote diff < 10 %.
-- expected result: one rows with
-- Schema for storing a subset of the Parliaments and Governments database
-- available at http://www.parlgov.org/


DROP SCHEMA IF EXISTS parlgov CASCADE;
CREATE SCHEMA parlgov;

SET SEARCH_PATH to parlgov;

-- A democratic country that is part of the OECD (Organization for
-- Economic Co-operation and Development: http://www.oecd.org) or the
-- European Union, and has a parliamentary system of government.
-- Countries with presidential systems are excluded.
CREATE TABLE country(
  id INT primary key,
  -- The full name of the country.
  name VARCHAR(50) NOT NULL UNIQUE,
  -- An abbreviation of the country's name, following the ISO alpha-3
  -- standard.  Reference: https://www.iso.org/iso-3166-country-codes.html
  abbreviation VARCHAR(10) UNIQUE,
  -- The date on which the country joined the OECD.
  oecd_accession_date DATE NOT NULL,
  -- The electoral system used by the country
  electoral_system varchar(100) NOT NULL,
  -- Years between parliamentary elections
  election_cycle INT NOT NULL
);

-- A political party, such as the New Democratic Party of Canada.
CREATE TABLE party(
  id INT PRIMARY KEY,
  -- The country in which this political party operates.
  country_id INT REFERENCES country(id),
  -- An abbreviation for the name of this party.
  name_short VARCHAR(10) NOT NULL,
  -- The full name of this party.
  name VARCHAR(100) NOT NULL,
  -- Further information about this party.
  description VARCHAR(1000),
  UNIQUE(country_id, name_short)
);

-- A "cabinet" is the set of government and opposition parties in parliament
-- as of each major change, such as an election or change of prime minister.
-- This table itself stores the start date of a cabinet and other general
-- information it.  Table cabinet_party, which references this table,
-- stores the political parties that were part of this cabinet.
CREATE TABLE cabinet(
  id INT PRIMARY KEY,
  -- The country in which this cabinet occurred.
  country_id INT REFERENCES country(id),
  -- The date on which this cabinet came into being.
  start_date DATE NOT NULL,
  -- A label for this cabinet, consisting of the family name of the
  -- prime minister and a roman numeral if he/she headed more than one
  -- cabinet.
  name VARCHAR(50) NOT NULL UNIQUE,
  -- A wikepedia entry or other webpage about this cabinet.
  wikipedia VARCHAR(500),
  -- Further information about this cabinet.
  description VARCHAR(1000),
  -- Further information about this cabinet.
  comment VARCHAR(1000),
  -- The previous cabinet for this country.  This attribute forms a
  -- "linked list" of cabinets for each country.
  -- Constraint: The country_id for this cabinet and the previous cabinet
  -- must be the same.
  previous_cabinet_id INT REFERENCES cabinet(id),
  -- The ID of the parliamentary election associated this cabinet.
  election_id INT
);

-- A party that was part of parliament during the period of a cabinet.
CREATE TABLE cabinet_party(
  id INT PRIMARY KEY,
  cabinet_id INT REFERENCES cabinet(id),
  party_id INT REFERENCES party(id),
  -- True iff this party fills the position of prime minister.
  pm BOOLEAN NOT NULL,
  -- Further information about this relationship between a party and cabinet.
  description VARCHAR(1000)
);

-- A parliamentary election is an election within a country to choose
-- a national government.  A European parliament election is an election,
-- held across all European Union countries, to choose national
-- representatives for the European parliament.
CREATE TYPE election_type AS ENUM(
	'European Parliament', 'Parliamentary election');

-- Election results for a parliamentary election or European parliament
-- election.  European parliament elections are recorded here by country.
CREATE TABLE election(
  id INT primary key,
  -- The country whose election information this is.
  country_id INT REFERENCES country(id),
  -- The date of this election.
  e_date DATE NOT NULL,
  -- A wikipedia entry or other webpage about this election.
  wikipedia VARCHAR(100),
  -- The number of seats available in this election
  seats_total INT NOT NULL,
  -- The number of citizens eligible to vote in this election
  electorate INT NOT NULL,
  -- The number of people who did vote in this election.
  votes_cast INT,
  -- The number of the votes cast that are valid.  A voter may "spoil"
  -- their vote either intentionally (in protest) or unintentionally (by
  -- filling it out incorrectly).  Only valid votes contribute to the
  -- election results.
  -- Constraint: votes_valid <= votes_cast <= electorate
  votes_valid INT,
  -- Further information about this election
  description VARCHAR(500),
  -- ID of the previous parliamentary election in this country, or
  -- NULL if there is no previous parliamentary election in the database.
  -- Note: Even EP elections have this attribute.
  -- Constraint: The country_id for this election and the previous
  -- parliamentary election must be the same.
  previous_parliament_election_id INT REFERENCES election(id),
  -- ID of the previous EP election in this country, or
  -- NULL if there is no previous EP election in the database.
  -- Note: Even parliamentary elections have this attribute.
  -- Constraint: The country_id for this election and the previous
  -- EP election must be the same.
  previous_ep_election_id INT REFERENCES election(id),
  -- The type of election this was.
  e_type election_type NOT NULL
);


-- Results, for each party, of a parliamentary election.
CREATE TABLE election_result(
  id INT PRIMARY KEY,
  -- The election that these results are for.
  election_id INT REFERENCES election(id),
  -- The party whose results these are.
  party_id INT REFERENCES party(id),
  -- If this party belongs to an alliance for this election, this is
  -- the ID of the election result associated with the head party
  -- in the alliance.  (All alliances have a head party.)
  alliance_id INT REFERENCES election_result(id),
  -- Number of seats the party won.
  seats INT,
  -- Number of valid votes that went to this party in this election.
  votes INT,
  -- Further information about this election result.
  description VARCHAR(1000),
  UNIQUE (election_id, party_id)
);

-- The position of a party on various idealogical dimensions.
-- These values were determined based on a number of published sources.
-- See http://www.parlgov.org/documentation/codebook/#election
CREATE TABLE party_position(
  party_id INT PRIMARY KEY REFERENCES party(id),
  -- This party's position on the left-wing/right-wing dimension.
  left_right REAL CHECK(left_right >= 0.0 AND left_right <= 10.0),
  -- This party's position on the economic (state/market) dimension.
  state_market REAL CHECK(state_market >= 0.0 AND state_market <= 10.0),
  -- This party's position on the cultural (liberty/authority) dimension.
  liberty_authority REAL
      CHECK(liberty_authority >= 0.0 AND liberty_authority <= 10.0)
);

-- Classification of political parties into families, such as "populist",
-- "conservative", or "religious".
CREATE TABLE party_family(
  party_id INT REFERENCES party(id),
  family VARCHAR(50) NOT NULL,
  PRIMARY KEY(party_id, family)
);

-- For countries that have a president in addition to a prime minister,
-- this table records its presidents.
CREATE TABLE politician_president(
  id INT PRIMARY KEY,
  -- The country for whom this was a president.
  country_id INT REFERENCES country(id),
  -- The start date of this presidency.
  start_date DATE NOT NULL,
  -- The end date of this presidency.
  end_date DATE,
  -- The party to which this president belonged.
  party_id INT REFERENCES party(id),
  -- Further information about this president.
  description VARCHAR(1000) NOT NULL,
  -- Further information about this president.
  comment VARCHAR(1000) NOT NULL
  -- Constraint: For any one country, there can be no overlap between
  -- presidency periods (the time from its start to its end date).
  -- There can be gaps.
);

insert into country values (0, 'c1', 'c1', '01-01-1950', 'es1', 4);

insert into election values (0, 0, '01-01-1950', 'wiki', 338, 18000000, 14000000, 13000000, 'desc', NULL, NULL, 'Parliamentary election');

insert into party values (0, 0, 'p1', 'p1', 'd1');
insert into party values (1, 0, 'p2', 'p2', 'd2');

insert into     election_result values (0, 0, 0, NULL, 300, 12100000, 'd1');
insert into     election_result values (1, 0, 1, NULL, 300, 12000000, 'd1');

insert into     cabinet values (0, 0, '01-01-1950', 'n1', 'wiki', 'd1', 'c1', NULL, 0);

insert into     cabinet_party values (0, 0, 0, true, 'd1');

-- results of query
--  electionid | countryname | winningparty | closerunnerup
-- ------------+-------------+--------------+---------------
--           0 | c1          | p1           | p2


DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS noNUll_election_results CASCADE;
DROP VIEW IF EXISTS alliance_votes CASCADE;
DROP VIEW IF EXISTS winner_alliances_votes CASCADE;
DROP VIEW IF EXISTS close_calls CASCADE;


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

create view alliance_party_votes as
  select alliance_votes.alliance_id, party_name, alliance_votes.election_id, total_votes
    from noNUll_election_results join alliance_votes
      on noNUll_election_results.election_id = alliance_votes.election_id
      and noNUll_election_results.alliance_id = alliance_votes.alliance_id;

/*create view winner_alliances_votes as
  select alliance_votes.alliance_id, total_votes, election_winners.election_id, election_winners.country_id
    from  election_winners join noNUll_election_results
      on election_winners.election_id = noNUll_election_results.election_id   --get right results
    join alliance_votes
      on election_winners.election_id = alliance_votes.election_id and
       noNUll_election_results.id = alliance_votes.alliance_id;     --get the winning alliance for an election*/

create view winner_alliances_votes as
 select alliance_votes.alliance_id, total_votes, election_winners.election_id, election_winners.country_id, noNUll_election_results.party_name
   from election_winners join noNUll_election_results
      on noNUll_election_results.party_id = election_winners.party_id
      and noNUll_election_results.election_id = election_winners.election_id
  join alliance_votes
     on noNUll_election_results.id = alliance_votes.alliance_id;

create view close_calls as
  select DISTINCT winner_alliances_votes.election_id as electionId, country.name as countryName,
         winner_alliances_votes.party_name as winningParty, alliance_party_votes.party_name as closeRunnerUp
         --alliance_votes.total_votes as atvotes,winner_alliances_votes.total_votes as wvotes, CAST(alliance_votes.total_votes as float)/winner_alliances_votes.total_votes as division
    from winner_alliances_votes join alliance_party_votes
      on winner_alliances_votes.election_id = alliance_party_votes.election_id   --get all other results for this election
      and winner_alliances_votes.alliance_id != alliance_party_votes.alliance_id -- dont compare winner with them seleves
    join country
      on winner_alliances_votes.country_id = country.id
    where CAST(alliance_party_votes.total_votes as float)/winner_alliances_votes.total_votes > 0.9; --finds votes with in 10%
