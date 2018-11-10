

SET SEARCH_PATH TO parlgov;
drop table if exists q7 cascade;

-- You must not change this table definition.

DROP TABLE IF EXISTS q7 CASCADE;
CREATE TABLE q7(
partyId INT,
partyFamily VARCHAR(50)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS all_EP CASCADE;
DROP VIEW IF EXISTS first_election CASCADE;
DROP VIEW IF EXISTS all_gap_EP CASCADE;
DROP VIEW IF EXISTS par_between_gap CASCADE;
DROP VIEW IF EXISTS election_winners CASCADE;
DROP VIEW IF EXISTS winning_parties_alliance CASCADE;
DROP VIEW IF EXISTS winning_parties CASCADE;
DROP VIEW IF EXISTS ans CASCADE;
-- ALl EP election.
create view all_EP as
  select id, previous_ep_election_id as pre_id
  from election where e_type = 'European Parliament';

-- All gap between each EP election.
create view all_gap_EP as
  select
  case when e2.e_date is null then '1753-01-01' else e2.e_date end as prev_date,
  e1.e_date as curr_date
  from all_EP as ep
  join election as e1 on ep.id = e1.id
  join election as e2 on ep.pre_id = e2.id;



-- All parliament elections happened between gaps of EP.
create view par_between_gap as
  select distinct e1.id as eid
  from election as e1, all_gap_EP
  where e1.e_date < all_gap_EP.curr_date and e1.e_date > all_gap_EP.prev_date
  and e1.e_type != 'European Parliament';



-- get all of the winning parties based on the cabinet
create view election_winners as
select   election.id as election_id , cabinet_party.party_id as party_id
from election join cabinet on election.id = cabinet.election_id
join cabinet_party on cabinet.id = cabinet_party.cabinet_id
where cabinet_party.pm = true;


-- Winning parties' alliance of parliament elections happened between gaps of EP.
create view winning_parties_alliance as
  select distinct er.election_id as eid, alliance_id as aid
  from election_result as er
  join par_between_gap as par on er.election_id = par.eid;


-- Wining parties of parliament elections happened between gaps of EP.
create view winning_parties as
  (select distinct party_id
  from election_result as er
  join par_between_gap as par on er.election_id = par.eid)
  UNION
  (select distinct er.party_id as party_id
  from election_result as er
  join winning_parties_alliance as wa on er.id = wa.aid)
  Union(select party_id from election_winners);




-- Final answer.
create view ans as
  select wp.party_id as partyID, pf.family as partyFamily
  from party_family as pf
  join winning_parties as wp on wp.party_id = pf.party_id;




-- the answer to the query
insert into q7 select * from ans
