
-- Test table
select * 
  into test 
  from cross_grid 
  where random() < 0.01 
  limit 1000;  
  

-- Method 1
-- ========  
select g.*, t.featureid into selection1
  from test t
  inner join gfdl_esm2m g on g.cellid = t.cellid;
-- Test 10 - Time: 271770 ms (3.6 minutes)
-- Test 100 - Time: 295683 ms (4.9 minutes)  
-- Test 1000 - Time: 320282 ms (5.3 minutes)  
 
select count(*) from selection1;
select * from selection1 limit 10;

drop table test, selection1;
 

-- Method 1 refined
-- ================
select featureid 
  into feature_list 
  from cross_grid 
  where random() < 0.01 
  limit 10;  

with s as (
  select featureid, cellid
  from cross_grid  
  where featureid in (
	select featureid 
	from feature_list)
)
select g.*, s.featureid into test1
  from s
  inner join gfdl_esm2m g on g.cellid = s.cellid;


 
-- Method 2
-- ========  

with s as (
  select * 
  from gfdl_esm2m
  where cellid in (
    select cellid 
	from test
  )
)
select s.*, t.featureid into selection2
from s
left join test t on s.cellid = t.cellid;

-- Test 10 - Time: 5026 ms (5.0 seconds)
-- Test 100 - Time: 9075 ms (9.1 seconds)
-- Test 1000 - Time: 31456 ms (31.5 seconds)


select count(*) from selection2;
select * from selection2 limit 10;

drop table test, selection2;








--select (201407661, 201407662, 201407670, 201407665, 201407671) into featureList;


-- Method 2 refined
-- ================
select featureid 
  into feature_list 
  from cross_grid 
  where random() < 0.01 
  limit 1000;  

with s as (
  select * 
  from gfdl_esm2m
  where cellid in (
    select cellid 
	from cross_grid
	where featureid in (
	  select featureid 
	  from feature_list
	)
  )
)
select s.*, c.featureid into test4
from s
left join (
  select cellid, featureid  
  from cross_grid 
    where featureid in (
	  select featureid 
	  from feature_list)
  ) c on s.cellid = c.cellid;
	
-- Test 10 - Time: 5047 ms (5 seconds)
-- Test 100 - Time: 8342 ms (8 seconds)  
-- Test 1000 - Time: 29172 ms (29 seconds)  
 
select count(*) from test4;
select * from test4 limit 10;

drop table feature_list, test4;





	
	

-- figure out how to make this one encompassing query



select cellid, featureid  
  from cross_grid 
  where featureid in (select featureid from feature_list);







select * into xx
  from gfdl_esm2m
  where cellid in (
    select cellid 
	from cross_grid
	where featureid in (select featureid from feature_list)
  );













select * into selection2
  from gfdl_esm2m
  where cellid in (
    select cellid 
	from test
  );
-- Time: 32101  
  
select s.*, t.featureid into selection3
  from selection2 s
  left join test t on s.cellid = t.cellid;
-- Time:  858ms










 
left join  
	
	
	t.cellid;

 
  
  
select * from gfdl_esm2m where lat = 48.125 and lon = -68.375;
  
select * from gfdl_esm2m, test where lat in test.latitude and lon in test.longitude;  