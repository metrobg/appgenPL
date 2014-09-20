SELECT
  PCLASS,
  INITCAP(P.DESCRIPTION) "CATEGORY",
  I.ITEM "ITEM #",
  VENDOR_ITEM "VENDOR #",
  UPPER(vend_name) "VENDOR NAME",
  MCODE,
  INITCAP(M.DESCRIPTION) "BRAND",
I.DESCRIPTION "ITEM DESCRIPTION",  --ITEM DESCRIPTIN WITH SHORT
--SUBSTR(I.DESCRIPTION,INSTR(I.DESCRIPTION, ',') +1 ) "ITEM DESCRIPTION",

  I.PKG "MASTER CASE",

  I.UOFM "UNIT",
KOSHER,
--to_number(trim(TO_CHAR(I.COST / 1000,'9999.000'))) "COST/UNIT",  ---COST/UNIT NORMAL COST

TO_NUMBER(TRIM(TO_CHAR(S.LAST_COST / 1000,'9999.000'))) "COST/UNIT",  ---LAST RECEIPT COST
  I.LIST "PRICE/UNIT",   ---LIST PRICE

--NVL(U.COST,0) "COST/MASTER CASE",   ---NORMAL COST/MASTER CASE
NVL(U.COST,TO_NUMBER(TRIM(TO_CHAR(S.LAST_COST / 1000,'9999.000')))) "COST/MASTER CASE",   ---LAST COST/MASTER CASE

  --TO_NUMBER(TRIM(TO_CHAR(S.AVG_COST / 1000,'9999.000'))) "Avg Cost",

  NVL(U.LIST,I.LIST) "PRICE/MASTER CASE",  ---LIST PRICE
  SOLD_MTD,
  SOLD_YTD,
  SALES_MTD "DOLLARS_SOLD_MTD",
  SALES_YTD "DOLLARS_SOLD_YTD",
  I.QOH,
  COMMITTED,
  AVAILABLE,
  ON_ORDER,
  AG_PERIOD(LAST_RECV) LAST_RECV,
  AG_PERIOD(LAST_SOLD) LAST_SOLD,
(select count( distinct CUSTOMER) from OE_ITMHIST where ITEM = i.ITEM)"# CUSTOMER BUYING",
CATALOG,
SEASONAL,
PROMOTION,
LIQUIDATION,
SPECIAL_ORDER,
SAMPLE,
CHILL,
REFER,
FROZEN,
PUBLIX,
GREENWISE,
BIN,
DIABETIC

FROM
  IV_ITMFIL I,
  IV_MCODE M,
  IV_PCLASS P ,
  IV_STATUS S,
  AP_VENFIL V,
  ADDL_UOFM u
WHERE
  1           = 1
AND PCLASS  != 9000
AND v.vend_id = I.PRIMARY_VENDOR
AND I.MCODE   = M.CODE
AND P.CLASS   = I.PCLASS
AND S.ITEM(+) = I.ITEM
and U.ITEM(+) = I.ITEM
ORDER BY 2;
