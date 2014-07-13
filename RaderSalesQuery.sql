SELECT
  CUSTNO,
  C.NAME,
  ZIP,
  SALESREP ||'-'||S.NAME REP,
  NVL(CCLASS,0) ||'-'||A.DESCRIPTION CCLASS,
  NVL(CTYPE,'I') ||'-'||T.DESCRIPTION CTYPE,
  COST_MTD,
  SALES_MTD,
  COST_YTD,
  SALES_YTD ,
  to_char(AG_DATE(last_sale),'mm/dd/yyyy') last_sale,
 NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND (TO_CHAR(PERIOD,'MON')  in ('JAN','FEB','MAR','APR','MAY','JUN')
               AND TO_CHAR(PERIOD,'yyyy') = '2014') 
                  AND CUSTNO = C.CUSTNO),0) "Jan - Jun 2014", 
  NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND TO_CHAR(PERIOD,'Mon YYYY')  = 'Feb 2013' 
                  AND CUSTNO = C.CUSTNO),0) "Feb 2013",
   NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND TO_CHAR(PERIOD,'Mon YYYY')  = 'Feb 2014' 
                  AND CUSTNO = C.CUSTNO),0) "Feb 2014",
  NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND TO_CHAR(PERIOD,'Mon YYYY')  = 'Mar 2013' 
                  AND CUSTNO = C.CUSTNO),0) "Mar 2013",
  NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND TO_CHAR(PERIOD,'Mon YYYY')  = 'Mar 2014' 
                  AND CUSTNO = C.CUSTNO),0) "Mar 2014",
  NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND TO_CHAR(PERIOD,'Mon YYYY')  = 'Apr 2013' 
                  AND CUSTNO = C.CUSTNO),0) "Apr 2013",
  NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND TO_CHAR(PERIOD,'Mon YYYY')  = 'Apr 2014' 
                  AND CUSTNO = C.CUSTNO),0) "Apr 2014",                 
  NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND TO_CHAR(PERIOD,'Mon YYYY')  = 'May 2013' 
                  AND CUSTNO = C.CUSTNO),0) "May 2013" , 
  NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND TO_CHAR(PERIOD,'Mon YYYY')  = 'May 2014' 
                  AND CUSTNO = C.CUSTNO),0) "May 2014" ,  
  NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND TO_CHAR(PERIOD,'Mon YYYY')   = 'Jun 2013' 
                  AND CUSTNO = C.CUSTNO),0) "Jun 2013"  ,                               
  NVL( (SELECT   SUM(AMOUNT)  FROM AR_BUYPROF   WHERE 1 = 1 AND TO_CHAR(PERIOD,'Mon YYYY')   = 'Jun 2014' 
                  AND CUSTNO = C.CUSTNO),0) "Jun 2014"  
FROM
  AR_CUSMAS C,
  AR_SLSMAN S,
  AR_CTYPE T ,
  AR_CCLASS A
WHERE 1 = 1   
and  C.SALESREP = S.CODE
AND T.CODE   = C.CTYPE
AND A.CODE   = TO_NUMBER(C.CCLASS) 
GROUP BY CUSTNO, C.NAME, ZIP, SALESREP ||'-'||S.NAME, NVL(CCLASS,0) ||'-'||A.DESCRIPTION, NVL(CTYPE,'I') ||'-'||T.DESCRIPTION, COST_MTD, SALES_MTD, COST_YTD, SALES_YTD, AG_DATE(LAST_SALE)
ORDER BY  1 desc