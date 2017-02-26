
-- Test of Person that person has no road connecting to that place -- KLAR!!

INSERT INTO Countries
VALUES('Rus');

INSERT INTO Areas
VALUES('Rus','Mos',7000000);
INSERT INTO Cities
VALUES('Rus','Mos',0);

INSERT INTO Areas
VALUES('Rus','San',2000000);
INSERT INTO Cities
VALUES('Rus','San',0);

INSERT INTO Persons
VALUES('Rus','19940202-7777','Hanna Cloneish','Rus','Mos',150000);

UPDATE Persons SET locationcountry = 'San', locationarea = 'Mos'
WHERE country = 'Rus'
  AND personnummer = '19940202-7777';
