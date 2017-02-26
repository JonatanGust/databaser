-- Test of Person that person cant afford moving -- KLAR!!

INSERT INTO Countries
VALUES('Den');

INSERT INTO Areas
VALUES('Den','Jyl',30000);
INSERT INTO Towns
VALUES('Den','Jyl');

INSERT INTO Areas
VALUES('Den','Ros',500000);
INSERT INTO Cities
VALUES('Den','Ros',0);

INSERT INTO Persons
VALUES('Den',
       '19940202-3333',
       'John Clonesson',
       'Den',
       'Jyl',
       5);

INSERT INTO Persons
VALUES('Den',
       '19940202-4444',
       'Lilly Clonesson',
       'Den',
       'Ros',
       150000);

INSERT INTO Roads
VALUES('Den',
       'Jyl',
       'Den',
       'Ros',
       'Den',
       '19940202-4444',
       111);

UPDATE Persons SET  locationcountry = 'Den', locationarea = 'Ros'
WHERE country = 'Den'
  AND personnummer = '19940202-3333';
