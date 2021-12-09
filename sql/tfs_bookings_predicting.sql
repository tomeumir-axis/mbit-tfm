
--
-- select all booking items XA only from Tenerife from 2019 with gd_status = OK+ and being on SALE TODAY (24/10/2021)
--
drop table bo_items_tfs_xa_2019;

create table bo_items_tfs_xa_2019 as
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
        , round(it.TOTAL_SALES_SC)		as i_TOTAL_SALES_SC
        -- , tkmts.f_get_gd_code('ACCOMMODATIONRATE', RATINGID) ac_rate_code
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
     where it.startdate between to_date('01.01.2019','dd.mm.yyyy') and to_date('31.12.2019','dd.mm.yyyy')
       and it.gd_Status = 'OK+'
       and it.od_stockid = s.od_stockid    
       and it.bo_headerid = h.bo_headerid
       and s.od_stockid = e.od_entityid
       and s.od_stockid =  d.od_stockid (+)
       and e.od_entityType='OD_STOCK'
       and g.gd_stocktypecode=s.gd_stocktypecode
       and g.gd_Stocktypegroupcode in ('XA') -- Only excursions/activities
       and nvl(s.gd_statussale,s.gd_status) in ('APPROVED','UPDATING','ONSALE','ONSALEREQ','CONFIRMED','INPROGRESS','NEW')
       and it.od_stockunitid = si.od_stockunitid
       and si.gd_stockTypeCode = stc.gd_stockTypeCode
       and si.gd_stockUnitCode = stc.gd_stockUnitCode
       and stc.languageCode = 'EN'
       --
       and h.od_clientid = cli.od_clientid
       --
       and it.od_resortOfficeid = 213 -- MTS Globe Spain - Tenerife
;

-- LA DEJAMOS!!! asi no hay que crearla despues :) 
                --removed ac_rate_code from the table and the query above because we filter items only : alter table bo_items_tfs_xa_2019 drop column ac_rate_code;
-- alter table bo_items_tfs_xa_2019 drop column ac_rate_code;
-- alter table bo_items_tfs_xa_2019 add ( ac_rate_code varchar2(10));

-- BUT WE have to add the column as a NUMBER 
alter table bo_items_tfs_xa_2019 drop column ac_avg_rating;
alter table bo_items_tfs_xa_2019 add ( ac_avg_rating varchar2(5));

-- some stats :

    select count(*) from bo_items_tfs_xa_2019; -->  25485 xa items
    
    select count( distinct stock_code ) from bo_items_tfs_xa_2019; --> 164 different xa codes (activities)
    
    
    select to_char(i_startdate, 'yyyy.mm') month, count(*) from bo_items_tfs_xa_2019 group by to_char(i_startdate, 'yyyy.mm') order by 1 asc;
    /*
    2019.01	    1338
    2019.02	    1680
    2019.03	    1627
    2019.04	    1341
    2019.05	    1395
    2019.06	    2301
    2019.07	    3139
    2019.08	    3268
    2019.09	    2903
    2019.10	    2857
    2019.11	    1919
    2019.12	    1717
    */


--
-- LEt's keep a table with all headerId for future joins and count how many bookings do we have
--  
create table bo_headers_ids_tfs_xa_2019 as select distinct h_BO_HEADERID from bo_items_tfs_xa_2019;

select count(*) from bo_headers_ids_tfs_xa_2019; --> 23.484 bookings


--
--  create the pax information pivot table
--

---- * ----- PAXES
-- ** PAXES ** -- booking_paxes_per_type.csv
-- how many paxes types has each booking

create table bo_pax_tfs_xa_2019 as
    select * from 
    (
        select h.h_bo_headerid, p.paxtype
          from tkmts.bo_pax p
             , bo_headers_ids_tfs_xa_2019 h
         where p.bo_headerid = h.h_bo_headerid 
    )
    pivot
    (
        count(paxtype)
        for paxtype in ('ADT','CHD','INF')
    )
    ;

alter table bo_pax_tfs_xa_2019 RENAME COLUMN "'ADT'" TO ADT;
alter table bo_pax_tfs_xa_2019 RENAME COLUMN "'CHD'" TO CHD;
alter table bo_pax_tfs_xa_2019 RENAME COLUMN "'INF'" TO INF;

alter table bo_pax_tfs_xa_2019 add( avg_adt_age number(3), lead_pax_age number(3) );

select * from bo_pax_tfs_xa_2019;

-- adding average age for ADT : booking_avg_adt_age.csv
begin
  for r in ( select h_bo_headerid
                 , round(avg(p.age)) avg_adt_age
              from tkmts.bo_pax p
                 , bo_headers_ids_tfs_xa_2019 h
             where p.bo_headerid = h.h_bo_headerid 
               and p.paxtype = 'ADT'
             group by h.h_bo_headerid
            )
  loop
    update bo_pax_tfs_xa_2019 set avg_adt_age = r.avg_adt_age where h_bo_headerid = r.h_bo_headerid;
  end loop;
  commit;
end;
/

select * from bo_pax_tfs_xa_2019;

begin
  for r in ( select p.bo_headerid, p.age
              from tkmts.bo_pax p
                 , bo_pax_tfs_xa_2019 bh
             where bh.h_bo_headerid = p.bo_headerid
               and p.isleadpax = 1
  )
  loop
    update bo_pax_tfs_xa_2019 set lead_pax_age = r.age where h_bo_headerid = r.bo_headerid;
  end loop;
  commit;
end;
/


--
--   OTHER SERVICES information (other items type : number of and selling_sc
--
--   Check if the bookings that the excursions belong to, include other services or not 
--    and if so get the count and the selling cost in system currency (euros) 
--   We do it only for hotel and transfer
-- 

-- drop table bo_services_tfs_xa_2019;
create table bo_services_tfs_xa_2019 as select * from bo_headers_ids_tfs_xa_2019;
alter table bo_services_tfs_xa_2019 add
(
    TR_NUM_OF_SERVICES	NUMBER,
    TR_TOTAL_SALES	NUMBER,
    XA_NUM_OF_SERVICES	NUMBER,
    XA_TOTAL_SALES	NUMBER,
    AC_NUM_OF_SERVICES	NUMBER,
    AC_TOTAL_SALES	NUMBER
);

select * from bo_services_tfs_xa_2019;

declare
  v_num_services number;
  v_sales_sc     number;
begin
  for r in ( select h_bo_headerid from bo_headers_ids_tfs_xa_2019)
  loop
    for s in (select g.gd_Stocktypegroupcode
                   , count(*) num_services
                   , round(sum(it.total_sales_sc)) sales_sc
              from tkmts.bo_item it 
                 , tkmts.od_stock st
                 , tkmts.gd_stocktype g
             where it.bo_headerid = r.h_bo_headerid
               and it.gd_Status = 'OK+'
               and it.od_stockid = st.od_stockid
               and st.gd_stocktypecode=g.gd_stocktypecode
               and g.gd_Stocktypegroupcode in ('TR','XA','AC')
             group by g.gd_Stocktypegroupcode
             )
    loop
      if s.gd_Stocktypegroupcode = 'TR' then
        UPDATE bo_services_tfs_xa_2019 set tr_num_of_services = s.num_services, tr_total_sales = s.sales_sc where h_bo_headerid = r.h_bo_headerid;
      elsif s.gd_Stocktypegroupcode = 'XA' then
        UPDATE bo_services_tfs_xa_2019 set xa_num_of_services = s.num_services, xa_total_sales = s.sales_sc where h_bo_headerid = r.h_bo_headerid;
      elsif s.gd_Stocktypegroupcode = 'AC' then
        UPDATE bo_services_tfs_xa_2019 set ac_num_of_services = s.num_services, ac_total_sales = s.sales_sc where h_bo_headerid = r.h_bo_headerid;
      end if;
    end loop;
  end loop;
  commit;
end;
/



select count(*) from bo_services_tfs_xa_2019 where xa_num_of_services > 1;

select * from bo_services_tfs_xa_2019;


--
--  * Add hotel rating for rows having ac_num_of_services > 0
--

declare
 v_od_stockid number;
 v_ac_rating number;
 avg_ac_rating number;
 num_services number;
begin
  for r in ( select h_bo_headerid 
               from bo_services_tfs_xa_2019 
              where ac_num_of_services > 0
               --and rownum < 6
         )
  loop
    --dbms_output.put_line('bo_services_tfs_xa_2019.h_bo_headerid:'||r.h_bo_headerid);
    -- for each booking... 
    avg_ac_rating := 0;
    num_services := 0;
    for h in ( select od_stockid from tkmts.bo_item where bo_headerid = r.h_bo_headerid and GD_STOCKTYPECODE = 'AC')
    loop
      -- dbms_output.put_line('   od_stockid:'||h.od_stockid);
      -- loop for each AC item of the booking.
        select to_number(substr(tkmts.f_get_gd_code('ACCOMMODATIONRATE', d.ratingId),1,1)) ac_rating
          into v_ac_rating
          from tkmts.od_stock s 
             , tkmts.od_stock_ac_detail d
         where s.od_stockid = h.od_stockid
           and s.od_stockid = d.od_stockid;          
        avg_ac_rating := avg_ac_rating + v_ac_rating;
        num_services := num_services + 1;
        --dbms_output.put_line('     v_ac_rating:'||v_ac_rating);
        --dbms_output.put_line('     avg_ac_rating:'||avg_ac_rating);
        --dbms_output.put_line('     num_services:'||num_services);
    end loop;
    if num_services > 0 then
    -- update the booking adding the avg ac rate only if the booking has one or more AC services
        update bo_items_tfs_xa_2019 set ac_avg_rating = to_char(round(avg_ac_rating/num_services,1),'99.9') where h_bo_headerid = r.h_bo_headerid;
    end if;
  end loop;
  commit;
end;
/


select to_number(substr(tkmts.f_get_gd_code('ACCOMMODATIONRATE', d.ratingId),1,1)) ac_rating
          -- into v_ac_rating
          from tkmts.od_stock s 
             , tkmts.od_stock_ac_detail d
         where s.od_stockid = 19790
           and s.od_stockid = d.od_stockid;   

select h_bo_headerid 
  from bo_services_tfs_xa_2019 
 where ac_num_of_services > 0
;


-- 
-- * ADstock coordinates
--
alter table bo_items_tfs_xa_2019 drop column i_latitud;
alter table bo_items_tfs_xa_2019 drop column i_longitud;
alter table bo_items_tfs_xa_2019 add (i_latitud VARCHAR2(25 CHAR), i_longitud VARCHAR2(25 CHAR));

declare
  v_lat varchar2(50);
  v_lon varchar2(50);
  procedure get_location( p_od_stockid in number, p_lat out varchar2, p_lon out varchar2)
  is
  begin
    select ad.latitud, ad.longitud
      into p_lat, p_lon
      from tkmts.od_entityAddress ea
         , tkmts.od_address ad
     where ea.od_entityID = p_od_stockid
       and ea.addressOrder = 0 -- main address
       and ad.od_addressId = ea.od_addressId;
  exception
    when others then
      p_lat := null;
      p_lon := null;
  end;
begin
  for r in ( select * from bo_items_tfs_xa_2019)
  loop
    get_location( r.i_od_stockid , v_lat ,  v_lon );
    -- dbms_output.put_line( r.stock_code  );
    -- dbms_output.put_line( r.stock_code +' '+ v_lat +' '+ v_lon );
    update bo_items_tfs_xa_2019 set i_latitud = v_lat, i_longitud = v_lon where i_od_stockid = r.i_od_stockid;
  end loop;
  commit;
end;
/


select stock_code, stock_name, i_latitud, i_longitud, count(*) from bo_items_tfs_xa_2019 group by stock_code, stock_name, i_latitud, i_longitud order by 5 desc;

select ad.latitud, ad.longitud
  from tkmts.od_entityAddress ea
     , tkmts.od_address ad
 where ea.od_entityID = 206908
   and ea.addressOrder = 0 -- main address
   and ad.od_addressId = ea.od_addressId;




--
-- * UNIFY all data and create the raw data table for a pandas' dataframe 
--
drop   table df_tfs_xa_2019;
create table df_tfs_xa_2019
as
select it.*
    , p.ADT
    , p.CHD
    , p.INF
    , p.AVG_ADT_AGE
    , p.LEAD_PAX_AGE
    , s.TR_NUM_OF_SERVICES
    , s.TR_TOTAL_SALES
    , s.XA_NUM_OF_SERVICES
    , s.XA_TOTAL_SALES
    , s.AC_NUM_OF_SERVICES
    , s.AC_TOTAL_SALES
  from bo_items_tfs_xa_2019 it
     , bo_pax_tfs_xa_2019 p
     , bo_services_tfs_xa_2019 s
 where it.h_bo_headerid = p.h_bo_headerid
   and it.h_bo_headerid = s.h_bo_headerid
order by it.h_bo_headerid
;


select * from df_tfs_xa_2019;

select * from df_tfs_xa_2019 where h_bo_headerid = 24799632;

--
-- SOME quick STATS ON RAW DATA
--
declare
  total_xa number;
  total_headers number;
  with_ac number;
  with_tr number;
  with_xa number;
  xa_num_of_services number;
  tr_num_of_services number;
  ac_num_of_services number;
  ac_with_rating number;
  distinct_xa number;
begin
    select count(*) into total_xa from df_tfs_xa_2019;
    select count(distinct h_bo_headerid) into total_headers from df_tfs_xa_2019;
    select count(*) into with_xa from df_tfs_xa_2019 where xa_num_of_services > 0;
    select count(*) into with_tr from df_tfs_xa_2019 where tr_num_of_services > 0;
    select count(*) into with_ac from df_tfs_xa_2019 where ac_num_of_services > 0;
    select sum(xa_num_of_services),sum(tr_num_of_services), sum(ac_num_of_services) into xa_num_of_services, tr_num_of_services, ac_num_of_services from df_tfs_xa_2019;
    select count(*) into ac_with_rating from df_tfs_xa_2019 where ac_avg_rating >0;
    select count(distinct stock_code) into distinct_xa from df_tfs_xa_2019;
    
    
    dbms_output.put_line('EXCURSION/ACTIVITY BOOKINGS - TENERIFE - From: 01/01/2019 Until:31/12/2019');
    dbms_output.put_line('==========================================================================');
    dbms_output.put_line('total_bookings = '||total_headers);
    dbms_output.put_line('total_items_xa = '||total_xa);
    dbms_output.put_line('  with_xa = '||with_xa||' - sum xa_num_of_services = '||xa_num_of_services);
    dbms_output.put_line('  with_tr = '||with_tr||' - sum tr_num_of_services = '||tr_num_of_services);
    dbms_output.put_line('  with_ac = '||with_ac||' - sum ac_num_of_services = '||ac_num_of_services);
    dbms_output.put_line('    with ac_rating info = '||ac_with_rating);
    dbms_output.put_line('');
    dbms_output.put_line('number of distinct xa = '||distinct_xa||' --> classes to predict');
    dbms_output.put_line('  class distribution: (stock_code,stock_name,total');
    dbms_output.put_line('      stock_code, stock_name,   total_2019');
    for r in (select stock_code, stock_name, count(*) as total from df_tfs_xa_2019 group by stock_code, stock_name order by 3 desc)
    loop
    dbms_output.put_line('      '||r.stock_code||','||r.stock_name||','||r.total);
    end loop;
end;
/



