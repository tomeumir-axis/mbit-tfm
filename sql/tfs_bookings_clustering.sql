
-- initial qery - only ITEMS => 73.203 rows
    select *
      from tkmts.bo_item it
         , tkmts.od_stock s
         , tkmts.gd_stocktype g
     where it.startdate between to_date('01.06.2021','dd.mm.yyyy') and to_date('15.09.2021','dd.mm.yyyy')
       and it.gd_Status = 'OK+'
       and it.od_resortOfficeid = 213 -- MTS Globe Spain - Tenerife
       and it.od_stockid = s.od_stockid 
       and s.gd_stocktypecode = g.gd_stocktypecode
       and g.gd_Stocktypegroupcode in ('AC', 'TR', 'XA') -- Only hotel, transfer and excursions/activities
 ;


--
-- select all booking items from Tenerife between 01/06 and 31/08 with gd_status = OK+
--
drop table tfs_all_bo_items;

create table tfs_all_bo_items_ex as
    select 
        -- header columns
         h.BO_HEADERID as h_BO_HEADERID
        ,h.BOOKINGDATE as h_BOOKINGDATE
        ,h.STARTDATE as h_STARTDATE
        ,h.ENDDATE as h_ENDDATE
        ,round(h.ENDDATE - h.STARTDATE) as h_DURATION
        ,round(h.STARTDATE - h.BOOKINGDATE) as h_daysbeforebook
        -- item columns
        ,it.BO_ITEMID		as i_BO_ITEMID
        ,it.BOOKINGDATE		as i_BOOKINGDATE
        ,it.STARTDATE		as i_STARTDATE
        ,it.ENDDATE		    as i_ENDDATE
        ,round(it.ENDDATE - it.STARTDATE) as i_DURATION
        ,round(it.STARTDATE-it.BOOKINGDATE) as i_daysbeforebook
        ,it.OD_RESORTOFFICEID		as i_OD_RESORTOFFICEID
        ,it.OD_STOCKID		as i_OD_STOCKID
        --,it.GD_STOCKTYPECODE		as i_GD_STOCKTYPECODE BT-BoatTrip, SF-Safari, etc.
        , g.gd_Stocktypegroupcode
        , tkmts.f_get_od_entityCode(it.od_stockid )stock_code
        , tkmts.f_get_od_entityName(s.od_stockid) stock_name
        , it.TOTAL_SALES_SC		as i_TOTAL_SALES_SC
        , tkmts.f_get_gd_code('ACCOMMODATIONRATE', RATINGID) ac_rate_code
        , stc.description serviceUnitDesc
        , tkmts.f_get_gd_code('CLIENTMARKET', clientMarketID) source_market
        , tkmts.F_GET_ISO_COUNTRY_ISO2(source_countryid) source_country_code
        , tkmts.F_GET_ISO_COUNTRYName(source_countryid) source_country_name
        -- extra columns
      from tkmts.bo_item it
         , tkmts.bo_header h
         , tkmts.od_stock s
         , tkmts.od_stock_ac_detail d
         , tkmts.od_entity e
         , tkmts.gd_stocktype g
         , tkmts.od_stockunit si
     , tkmts.gd_stockUnitCodeLng stc
     , tkmts.od_client cli
     where it.startdate between to_date('01.06.2021','dd.mm.yyyy') and to_date('15.09.2021','dd.mm.yyyy')
       and it.gd_Status = 'OK+'
       and it.od_stockid = s.od_stockid    
       and it.bo_headerid = h.bo_headerid
       and s.od_stockid = e.od_entityid
       and s.od_stockid =  d.od_stockid (+)
       and e.od_entityType='OD_STOCK'
       and g.gd_stocktypecode=s.gd_stocktypecode
       and g.gd_Stocktypegroupcode in ('XA') -- Only hotel, transfer and excursions/activities
       -- and g.gd_Stocktypegroupcode in ('AC', 'TR', 'XA') -- Only hotel, transfer and excursions/activities
       -- and g.gd_Stocktypegroupcode = 'AC' -- Only hotel, transfer and excursions/activities
       --and nvl(s.gd_statussale,s.gd_status) in ('APPROVED','UPDATING','ONSALE','ONSALEREQ','CONFIRMED','INPROGRESS','NEW')
       and it.od_stockunitid = si.od_stockunitid
       and si.gd_stockTypeCode = stc.gd_stockTypeCode
       and si.gd_stockUnitCode = stc.gd_stockUnitCode
       and stc.languageCode = 'EN'
       --
       and h.od_clientid = cli.od_clientid
       --
       and it.od_resortOfficeid = 213 -- MTS Globe Spain - Tenerife
       -- and it.od_resortOfficeid = 83696 -- DXB	MTS Dubai
       --and it.od_resortOfficeid =127 -- PMI
       --and rownum < 1001
;

select count(*) from tfs_all_bo_items; -- 73.250 rows

-- LEt's clean up Hotel RATINGS - as a number only
select ac_rate_code, count(*) from tfs_all_bo_items group by ac_rate_code order by 2 desc;
/*
null	49979
4STARS	11496
5STARS	4873
3STARS	3045
3KEYS	2575
2KEYS	717
2STARS	210
TBD	160
1STAR	130
1KEY	45
NR	20
*/

alter table tfs_all_bo_items add (ac_Rating number(2));

update tfs_all_bo_items set ac_rating = to_number(substr(ac_rate_code,1,1)) where ac_rate_code is not null and ac_rate_code not in ('NR','TBD');
commit;

select ac_rating, count(*) from tfs_all_bo_items group by ac_rating order by 2 desc;
-------  


-- LEt's keep a table with all headerId 
create table tfs_all_only_headerid as select distinct h_BO_HEADERID from tfs_all_bo_items;

select count(*) from tfs_all_only_headerid;
-- 37.083 bookings

select count(*) from tfs_all_bo_items;
-- 73.351 services booked

-- check number of bookings having a lot of services (probably groups)
select h_BO_HEADERID, count(*) services from tfs_all_bo_items group by h_BO_HEADERID order by 2 desc;

-- delete bookings with more than 10 services
delete from tfs_all_bo_items where h_BO_HEADERID in ( select h_BO_HEADERID from (
                                                                                 select h_BO_HEADERID, count(*) services from tfs_all_bo_items group by h_BO_HEADERID having count(*) > 10
                                                                                )
                                                    )
;
commit;



select * from tfs_all_bo_items
--where 
--i_gd_stockTypeCode != gd_stockTypeGroupCode
;

-- How many items bookied by type
select gd_Stocktypegroupcode, count(*) from tfs_all_bo_items group by gd_Stocktypegroupcode;
-- AC	23314
-- TR	47821
-- XA	 2216


select * from pmi_all_bo_items;
select gd_Stocktypegroupcode, count(*) from pmi_all_bo_items group by gd_Stocktypegroupcode;
-- PMI 175.059 booking items
   ------------
-- AC	42.440
-- TR  130.239
-- XA	 2.380


-- Proportion of items that has no selling cost by type
select count(*)
  from TFS_ALL_BO_ITEMS it
  where it.gd_Stocktypegroupcode = 'AC'
    and i_TOTAL_SALES_SC = 0 or i_TOTAL_SALES_SC is null
;
-- 16284 of 23314 'AC' have sales = 0 or null => 69% !!! 
--    57 of 47820 'TR' have sales = 0 or null
--    82 of  2216 'XA' have sales = 0 or null

-- Number of differen XA booked
select count( distinct stock_code ) , count(*)
  from TFS_ALL_BO_ITEMS it
  where it.gd_Stocktypegroupcode = 'XA'
;
-- 47 diff. activities for 2216 bookings

-- Ranking 
select  stock_code  , stock_name, count(*), round(avg(i_TOTAL_SALES_SC)) avg_price,  round(sum(i_TOTAL_SALES_SC)) total_amount, count(*) * round(avg(i_TOTAL_SALES_SC)) check_total
  from TFS_ALL_BO_ITEMS it
  where it.gd_Stocktypegroupcode = 'XA'
  group by stock_code, stock_name
order by 3 desc
;


---- * ----- PAXES
-- ** PAXES ** -- booking_paxes_per_type.csv
-- how many paxes types has each booking

create table tfs_all_bo_header_paxes as
select * from 
(
    select h.h_bo_headerid, p.paxtype
      from tkmts.bo_pax p
         , tfs_all_only_headerid h
     where p.bo_headerid = h.h_bo_headerid 
    order by bo_headerid
)
pivot
(
    count(paxtype)
    for paxtype in ('ADT','CHD','INF')
)
;

alter table tfs_all_bo_header_paxes RENAME COLUMN "'ADT'" TO ADT;
alter table tfs_all_bo_header_paxes RENAME COLUMN "'CHD'" TO CHD;
alter table tfs_all_bo_header_paxes RENAME COLUMN "'INF'" TO INF;

alter table tfs_all_bo_header_paxes add( avg_adt_age number(3), lead_pax_age number(3) );

select * from tfs_all_bo_header_paxes;

-- adding average age for ADT : booking_avg_adt_age.csv
begin
  for r in ( select h_bo_headerid
                 --, to_char(round(avg(age),2),'9,999.99') avg_adt_age
                 , round(avg(age),2) avg_adt_age
              from tkmts.bo_pax p
                 , tfs_all_only_headerid h
             where p.bo_headerid = h.h_bo_headerid 
               and paxtype = 'ADT'
             group by h_bo_headerid
            order by h_bo_headerid
            )
  loop
    update tfs_all_bo_header_paxes set avg_adt_age = NVL(r.avg_adt_age,0) where h_bo_headerid = r.h_bo_headerid;
  end loop;
  commit;
end;
/

select * from tfs_all_bo_header_paxes;

begin
  for r in ( select p.bo_headerid, p.age
              from tkmts.bo_pax p
                 , tfs_all_bo_header_paxes bh
             where bh.h_bo_headerid = p.bo_headerid
               and p.isleadpax = 1
  )
  loop
    update tfs_all_bo_header_paxes set lead_pax_age = NVL(r.age,0) where h_bo_headerid = r.bo_headerid;
  end loop;
  commit;
end;
/

select * from tfs_all_bo_header_paxes;


---- * ------ 
-- BILLINGS - shall we exclude AC amounts because there are many many without billing because they are direct payment.
--                                NOT YET !!!       

create table tfs_all_bo_header_services as
select * from 
(
    select boex.h_bo_headerid, gd_stocktypegroupcode,
       round(sum(boex.i_total_sales_sc)) total_sales_in_systemcurrency
  from tfs_all_bo_items boex
  --where boex.gd_stocktypegroupcode = 'AC' -- excluding hotel
group by boex.h_bo_headerid, gd_stocktypegroupcode
)
pivot
(
    count(gd_stocktypegroupcode) num_of_services, sum(total_sales_in_systemcurrency) total_sales
    for gd_stocktypegroupcode in ('TR','XA','AC')
)
;

alter table tfs_all_bo_header_services RENAME COLUMN "'TR'_NUM_OF_SERVICES" TO tr_num_of_services;
alter table tfs_all_bo_header_services RENAME COLUMN "'XA'_NUM_OF_SERVICES" TO xa_num_of_services;
alter table tfs_all_bo_header_services RENAME COLUMN "'AC'_NUM_OF_SERVICES" TO ac_num_of_services;
alter table tfs_all_bo_header_services RENAME COLUMN "'TR'_TOTAL_SALES" TO tr_total_sales;
alter table tfs_all_bo_header_services RENAME COLUMN "'XA'_TOTAL_SALES" TO xa_total_sales;
alter table tfs_all_bo_header_services RENAME COLUMN "'AC'_TOTAL_SALES" TO ac_total_sales;


select * from tfs_all_bo_header_services;

--
--  * GROUP ALL INFO at HEADER level
--
create table df_bookings_v3 
as
  select tfs_bookings.h_BO_HEADERID
        ,tfs_bookings.h_BOOKINGDATE
        ,tfs_bookings.h_STARTDATE
        ,tfs_bookings.h_ENDDATE
        ,tfs_bookings.h_DURATION
        ,tfs_bookings.h_daysbeforebook
        -- item columns
        ,tfs_bookings.source_country_code
        ,tfs_bookings.source_country_name
        ,tfs_bookings.max_ac_rating
        --
        ,pax.ADT
        ,pax.CHD
        ,pax.INF
        ,pax.AVG_ADT_AGE
        ,pax.LEAD_PAX_AGE
        --
        ,bs.TR_NUM_OF_SERVICES
        ,bs.XA_NUM_OF_SERVICES
        ,bs.AC_NUM_OF_SERVICES
        ,bs.TR_TOTAL_SALES
        ,bs.XA_TOTAL_SALES
        ,bs.AC_TOTAL_SALES
    from
        ( 
        select h_BO_HEADERID
                ,h_BOOKINGDATE
                ,h_STARTDATE
                ,h_ENDDATE
                ,h_DURATION
                ,h_daysbeforebook
                , source_country_code
                , source_country_name
                ,max(ac_rating) max_ac_rating  
          from tfs_all_bo_items
          group by h_BO_HEADERID
                ,h_BOOKINGDATE
                ,h_STARTDATE
                ,h_ENDDATE
                ,h_DURATION
                ,h_daysbeforebook
                -- item columns
                , source_country_code
                , source_country_name
        ) tfs_bookings
        ,tfs_all_bo_header_services bs
        ,tfs_all_bo_header_paxes pax
    where tfs_bookings.h_bo_headerid = bs.h_bo_headerid
      and tfs_bookings.h_bo_headerid = pax.h_bo_headerid
;




--
select * from df_bookings_v3;

select count(*) from df_bookings_v3; -- 37078 bookings
  
select count(*) total_filtered
     , sum(XA_NUM_OF_SERVICES) xa
     , sum(TR_NUM_OF_SERVICES) tr
     , sum(AC_NUM_OF_SERVICES) ac
  --from df_bookings_v3 where XA_NUM_OF_SERVICES > 0;   -- 2046	2046	   16	   13
  --from df_bookings_v3 where TR_NUM_OF_SERVICES > 0; --  30275	  16	30275	16032
  from df_bookings_v3 where AC_NUM_OF_SERVICES > 0;    -- 20806	  13	16032	20806


  XA_NUM_OF_SERVICES > 0;2046;2046;16;13
  TR_NUM_OF_SERVICES > 1;30275;16;30275;16032
  AC_NUM_OF_SERVICES > 0;20806;13;16032;20806








