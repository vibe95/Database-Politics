--Scenario:Same as senario for q1_self_correct2 but theres an alliance between p1 and p3 for seoncd election
--         with 3 parties, and 2 elections. 2 parties in the first election. all parites are in the second elections
--expected: return average parties position for p1 & p2 for first election and average of all parites for second election

insert into country values (0, 'c1', 'c1', '01-01-1950', 'es1', 4);

insert into election values (0, 0, '01-01-1950', 'wiki', 338, 18000000, 14000000, 13000000, 'desc', NULL, NULL, 'Parliamentary election');
insert into election values (1, 0, '01-01-2001', 'wiki', 338, 18000000, 14000000, 13000000, 'desc', 0, NULL, 'Parliamentary election');

insert into party values (0, 0, 'p1', 'p1', 'd1');
insert into party values (1, 0, 'p2', 'p2', 'd2');
insert into party values (2, 0, 'p3', 'p3', 'd2');


insert into party_position values (0, 5, 5, 5);
insert into party_position values (1, 9, 9, 9);
insert into party_position values (2, 2, 2, 2);

insert into	election_result values (0, 0, 0, NULL, 300, 12000000, 'd1');
insert into	election_result values (1, 1, 0, NULL, 300, 12000000, 'd1');
insert into	election_result values (2, 1, 1, NULL, 300, 12000000, 'd1');
insert into	election_result values (3, 0, 2, NULL, 300, 12000000, 'd1');
insert into	election_result values (4, 1, 2, 1, 300, 12000000, 'd1');

insert into	cabinet values (0, 0, '01-01-1950', 'n1', 'wiki', 'd1', 'c1', NULL, 0);
insert into	cabinet values (1, 0, '01-01-2001', 'n2', 'wiki', 'd2', 'c2', 0, 1);

insert into	cabinet_party values (0, 0, 0, true, 'd1');
insert into	cabinet_party values (1, 1, 0, true, 'd1');

-- excpected results of query
-- century | country | left_right | state_market | liberty_authority
-- ---------+---------+------------+--------------+-------------------
-- 20      | c1      |        3.5 |          3.5 |               3.5
-- 21      | c1      |        6.25 |         6.25 |              6.25

--Note avearge of alliance for 2001 election is 3.5
--then total average for all alliance is (3.5(p1&p3) + 9(p2))/2 = 6.25

--results from my code
-- century | country | left_right | state_market | liberty_authority
-- ---------+---------+------------+--------------+-------------------
-- 20      | c1      |        3.5 |          3.5 |               3.5
-- 21      | c1      |       6.25 |         6.25 |              6.25
