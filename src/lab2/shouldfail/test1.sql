
-- Test of Person that you should not update the Government -- KLAR!!

INSERT INTO Countries
VALUES('Swe');

INSERT INTO Areas
VALUES('Swe','Gbg',2000000);
INSERT INTO Cities
VALUES('Swe','Gbg',0);

INSERT  INTO  Persons
VALUES(' ',' ','The government','Swe','Gbg',100000000000);

UPDATE Persons SET locationcountry = 'Swe', locationarea = 'Gbg'
WHERE country = ' '
  AND personnummer = ' ';
