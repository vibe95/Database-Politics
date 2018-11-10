--Scenario: with 2 parties, and 2 elections. Only one party in the first election. Both parites are in the second elections.
--expected: return sole parties position for first election and average of both parites for second election

insert into country values (0, 'c1', 'c1', '01-01-1950', 'es1', 4);

insert into election values (0, 0, '01-01-1950', 'wiki', 338, 18000000, 14000000, 13000000, 'desc', NULL, NULL, 'Parliamentary election');
insert into election values (1, 0, '01-01-2001', 'wiki', 338, 18000000, 14000000, 13000000, 'desc', 0, NULL, 'Parliamentary election');

insert into party values (0, 0, 'p1', 'p1', 'd1');
insert into party values (1, 0, 'p2', 'p2', 'd2');

insert into party_position values (0, 5, 5, 5);
insert into party_position values (1, 9, 9, 9);

insert into	election_result values (0, 0, 0, NULL, 300, 12000000, 'd1');
insert into	election_result values (1, 1, 0, NULL, 300, 12000000, 'd1');
insert into	election_result values (2, 1, 1, NULL, 300, 12000000, 'd1');

insert into	cabinet values (0, 0, '01-01-1950', 'n1', 'wiki', 'd1', 'c1', NULL, 0);
insert into	cabinet values (1, 0, '01-01-2001', 'n2', 'wiki', 'd2', 'c2', 0, 1);

insert into	cabinet_party values (0, 0, 0, true, 'd1');
insert into	cabinet_party values (1, 1, 0, true, 'd1');

-- Expected results of query
--  century | country | left_right | state_market | liberty_authority
-- ---------+---------+------------+--------------+-------------------
--  20      | c1      |          5 |            5 |                 5
--  21      | c1      |          7 |            7 |                 7


-- Result from my code
--  century | country | left_right | state_market | liberty_authority
-- ---------+---------+------------+--------------+-------------------
--  20      | c1      |          5 |            5 |                 5
--  21      | c1      |          7 |            7 |                 7
