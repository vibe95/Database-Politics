

SET SEARCH_PATH TO parlgov;
drop table if exists q3 cascade;

-- You must not change this table definition.

create table q3(
country VARCHAR(50),
num_dissolutions INT,
most_recent_dissolution DATE,
num_on_cycle INT,
most_recent_on_cycle DATE
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS first_election CASCADE;
DROP VIEW IF EXISTS tuples CASCADE;
DROP VIEW IF EXISTS off_cycle CASCADE;
DROP VIEW IF EXISTS on_cycle CASCADE;
DROP VIEW IF EXISTS count_off CASCADE;
DROP VIEW IF EXISTS count_on CASCADE;
DROP VIEW IF EXISTS most_off CASCADE;
DROP VIEW IF EXISTS most_on CASCADE;
DROP VIEW IF EXISTS ans CASCADE;

-- first election of each country and their election_cycle.
create view first_election as
  select country.id as cid, e1.id as eid
  from country join election as e1 on country.id = e1.country_id
  join election as e2 on e1.country_id = e2.country_id
  group by country.id, e1.id
  having e1.e_date = min(e2.e_date)
  ;
-- tuples of two elections.
create view tuples as
  select country.id as cid, e1.id as eid, e_date, previous_parliament_election_id as prev_eid, election_cycle as e_cycle
  from country join election as e1 on country.id = e1.country_id
  group by e1.id, country.id;


-- off cycle eids.
create view off_cycle as
  select cid, eid
  from tuples
  join election as e1 on cid = e1.country_id and eid = e1.id
     join election as e2 on cid = e2.country_id and prev_eid = e2.id

       group by cid, tuples.eid, e1.id, e2.id, e_cycle
  having extract(year from e1.e_date) - extract(year from e2.e_date) < e_cycle;


-- on cycle eids.
create view on_cycle as
  select cid, eid
  from tuples
  join election as e1 on cid = e1.country_id and eid = e1.id
     join election as e2 on cid = e2.country_id and prev_eid = e2.id
       group by cid, tuples.eid, e1.id, e2.id, e_cycle
  having extract(year from e1.e_date) - extract(year from e2.e_date) = e_cycle
  UNION
  (select * from first_election);

-- count off_cycle.
create view count_off as
  select cid, count(eid) as num_dissolutions
  from off_cycle
  group by off_cycle.cid;


-- count num_on_cycle
create view count_on as
  select cid, count(eid) as num_on_cycle
  from on_cycle
  group by on_cycle.cid;

-- most recent off cycle.
create view most_off as
  select cid, max(e_date) as most_recent_dissolution
  from off_cycle join election on eid = election.id and cid = election.country_id
  group by off_cycle.cid;

-- most recent on cycle.
  create view most_on as
    select cid, max(e_date) as most_recent_on_cycle
    from on_cycle join election on eid = election.id and cid = election.country_id
    group by on_cycle.cid;

-- combine the answers.
 create view ans as
   select name, num_dissolutions, most_recent_dissolution, num_on_cycle, most_recent_on_cycle
   from country
      join count_off
        on country.id = count_off.cid
      join count_on
        on count_off.cid = count_on.cid
      join most_off
        on count_on.cid = most_off.cid
      join most_on
        on most_off.cid = most_on.cid
      group by country.id, num_dissolutions, most_recent_dissolution, num_on_cycle, most_recent_on_cycle;



-- the answer to the query
insert into q3 select * from ans;
