create database ipl_db;

use ipl_db;


# 1. Top 10 batsmen based on past 3 years total runs scored.
select batsmanname, sum(runs) runs
from fact_bating_summary
group by batsmanname
order by runs desc
limit 10
; 
# 2. Top 10 batsmen based on past 3 years batting average. (min 60 balls faced in
# each season)
with c1 as 
	(select batsmanname
    , year(matchdate) year
    ,  sum(runs) total_runs
    , sum(balls) faced_balls
    , sum(outs) total_out
    , case when sum(balls)>=60 then 1 else 0 end met_c
    from fact_bating_summary b
    join dim_match_summary m on b.match_id=m.match_id
    group by batsmanname, year(matchdate)
    )
    
select batsmanname, sum(total_runs) runs
, sum(faced_balls) balls
, sum(total_out) outs
, sum(met_C) met_c
, round(sum(total_runs)/sum(total_out),2)  batting_avg
from c1
group by batsmanname
having sum(met_c) =3
order by batting_avg desc
limit 10
;

# 3. Top 10 batsmen based on past 3 years strike rate (min 60 balls faced in each
# season)

with c1 as 
	(select batsmanname
    , year(matchdate) year
    ,  sum(runs) total_runs
    , sum(balls) faced_balls
    , sum(outs) total_out
    , case when sum(balls)>=60 then 1 else 0 end met_c
    from fact_bating_summary b
    join dim_match_summary m on b.match_id=m.match_id
    group by batsmanname, year(matchdate)
    )
    
select batsmanname, sum(total_runs) runs
, sum(faced_balls) balls
, sum(total_out) outs
, sum(met_C) met_c
, round(100*sum(total_runs)/sum(faced_balls),1)  strikerate
from c1
group by batsmanname
having sum(met_c) =3
order by strikerate desc
limit 10
;

# 4. Top 10 bowlers based on past 3 years total wickets taken.
select * from fact_bowling_summary;

select bowlername, sum(wickets) wickets
from fact_bowling_summary
group by bowlername
order by wickets desc
limit 10;    

# 5. Top 10 bowlers based on past 3 years bowling average. (min 60 balls bowled in
# each season)

with c1 as
	(
		select *, (floor(overs)*6 
        + round( overs - floor(overs))*10 ) total_balls
        from fact_bowling_summary
    )

, c2 as 
	(
		select bowlername,
			year(matchdate) years
			, sum(wickets) Wickets
            , sum(total_balls) balls
            , sum(runs) runs
            , case when sum(total_balls)>=60 then 1 else 0 end met_c
		from c1 b
         join dim_match_summary m
        on b.match_id=m.match_id
        group by bowlername, years 
        )
        
select bowlername, sum(wickets) wickets, sum(balls) balls 
, round(sum(runs)/sum(wickets),1) avg_bowling
from c2
group by bowlername
having sum(met_c) =3
order by avg_bowling
limit 10
;


# 6. Top 10 bowlers based on past 3 years economy rate. (min 60 balls bowled in
# each season)

with c1 as
	(
		select *, (floor(overs)*6 
        + round( overs - floor(overs))*10) total_balls
        from fact_bowling_summary
    )

, c2 as 
	(
		select bowlername,
			year(matchdate) years
            , sum(overs) overs
			, sum(wickets) Wickets
            , sum(total_balls) balls
            , sum(runs) runs
            , case when sum(total_balls)>=60 then 1 else 0 end met_c
		from c1 b
         join dim_match_summary m
        on b.match_id=m.match_id
        group by bowlername, years 
        )
        
select bowlername, sum(wickets) wickets, sum(balls) balls 
, round(sum(runs)/(sum(overs)),2) economy_rate
from c2
group by bowlername
having sum(met_c) =3
order by economy_rate
limit 10
;


# 7. Top 5 batsmen based on past 3 years boundary % (fours and sixes).
with c1 as 
	(
		select batsmanname, year(matchdate) years
        , sum(4s*4+6s*6) boundary_runs, sum(runs) total_runs
        , case when sum(balls) >=60 then 1 else 0 end met_c
        from fact_bating_summary b
        join dim_match_summary m on b.match_id=m.match_id
        group by batsmanname, year(matchdate)
    )

select batsmanname
	, sum(boundary_runs) boundary_runs
	, sum(total_runs) total_runs 
    , round(100*sum(boundary_runs)/sum(total_runs),2) boundary_pct
from c1
group by batsmanname
having sum(met_C)=3
order by boundary_pct desc
limit 5
;

# 8. Top 5 bowlers based on past 3 years dot ball %.
with c1 as
	(
		select *, (floor(overs)*6 
        + round( overs - floor(overs))*10 ) total_balls
        from fact_bowling_summary
    )

, c2 as 
	(
		select bowlername,
			year(matchdate) years
            , sum(total_balls) balls
            , sum(0s) zeros
            , case when sum(total_balls)>=60 then 1 else 0 end met_c
		from c1 b
         join dim_match_summary m
        on b.match_id=m.match_id
        group by bowlername, years 
        )
        
select bowlername, sum(balls) balls 
, round(100*sum(zeros)/sum(balls),2) dot_prct
from c2
group by bowlername
having sum(met_c) =3
order by dot_prct desc
limit 10
;

# 9. Top 4 teams based on past 3 years winning %.
with c1 as 
	(
	select team1 team, sum(case when team1 = winner then 1 else 0 end)  Won_Match
    , count(team1) Total_Match
	from dim_match_summary
	group by team1
	union all
    select team2 team, sum(case when team2 = winner then 1 else 0 end)  Won_Match
    , count(team2) Total_Match
	from dim_match_summary
	group by team2
    )

select team, sum(won_match) won , sum(total_match) total
, round(100*sum(won_match)/sum(total_match),2) team_pct
from c1
group by team
order by won desc, team 
;



# 10.Top 2 teams with the highest number of wins achieved by chasing targets over
# the past 3 years.

with c1 as 
	(
    select team1 team
    , sum( case when team1=winner then 1 else 0 end) total_won_match
    from dim_match_summary
    group by team1
    union all
    select team2 team2
    , sum(case when team2=winner then 1 else 0 end) total_won_match
    from dim_match_summary
    group by team2
    )
, c2 as 
	(
		select winner 
        , count(*) won
        from dim_match_summary
        where winner=team2
        group by winner
    )

select team
, won
, sum(total_won_match) total_match
, round(100*won/ sum(total_won_match), 2) team_chased_pct
from c1 
join c2 on c1.team=c2.winner
group by team
order by won desc, team
;
