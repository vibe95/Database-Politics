

SET SEARCH_PATH TO parlgov;
drop table if exists q4 cascade;

-- You must not change this table definition.


CREATE TABLE q4(
  country VARCHAR(50),
  num_elections INT,
  num_repeat_party INT,
  num_repeat_pm INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS num_elections CASCADE;
DROP VIEW IF EXISTS tuples CASCADE;
DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS same_party_tuples CASCADE;
DROP VIEW IF EXISTS new_name CASCADE;
DROP VIEW IF EXISTS repeated_name CASCADE;
DROP VIEW IF EXISTS num_repeat_pm CASCADE;
DROP VIEW IF EXISTS ans CASCADE;


-- Number of elections in total for each country.
CREATE VIEW num_elections as
select country.id as cid, count( election.id) as num_elections
from country join election on country.id = election.country_id
group by country.id

;





-- tuples sequential elections.
create view tuples as
select country.id as cid, e1.id as eid,
previous_parliament_election_id as prev_eid
from country join election as e1 on country.id = e1.country_id
group by e1.id, country.id;


-- get all of the winning parties based on the cabinet
create view election_winners as
select   election.id as election_id , cabinet_party.party_id
from election join cabinet on election.id = cabinet.election_id
join cabinet_party on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;



-- Two sequential elections won by the same party.
create view same_party_tuples as
select distinct tuples.cid as cid, count( ew1.party_id) as num_repeat_party
from tuples
join election_winners as ew1 on tuples.eid = ew1.election_id
join election_winners as ew2 on tuples.prev_eid = ew2.election_id
where ew1.party_id = ew2.party_id
group by tuples.cid;


-- new name without the Roman regex.
create view new_name as
  select id, country_id, regexp_replace(name::text, '([A-Za-z]*?)[ IV]+$', '\1') as name
  from cabinet;

-- repeated_name.
create view repeated_name as
select distinct n2.country_id as cid, n2.name as name
from new_name as n1
join new_name as n2 on n1.name = n2.name
where n2.id > n1.id;

-- count the names.
create view num_repeat_pm as
select distinct r1.cid as cid, count(distinct r1.name) as num_repeat_pm
from repeated_name as r1
group by r1.cid;

-- Combine the results.
create view ans as
select country.name as country, num_elections, num_repeat_party, num_repeat_pm
from country
join num_elections on country.id = num_elections.cid
join same_party_tuples on num_elections.cid = same_party_tuples.cid
join num_repeat_pm on same_party_tuples.cid = num_repeat_pm.cid
group by country.id,  num_elections, num_repeat_party, num_repeat_pm;
  -- the answer to the query
  INSERT INTO q4  select * from ans;
