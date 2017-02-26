-- Test of Person that person cant afford staying in that city -- KLAR!!

INSERT INTO Countries
VALUES('Den');

INSERT INTO Areas
VALUES('Den','Ros',500000);
INSERT INTO Cities
VALUES('Den','Ros',0);

INSERT INTO Areas
VALUES('Den','Kob',500000);
INSERT INTO Cities
VALUES('Den','Kob',0);

INSERT INTO Persons
VALUES('Den',
       '19940202-9999',
       'Than Clones',
       'Den',
       'Kob',
       150000 );
INSERT INTO Hotels
VALUES('Hotel KobenClone',
     'Den',
     'Kob',
     'Den',
     '19940202-9999');

INSERT INTO Roads
VALUES('Den',
       'Ros',
       'Den',
       'Kob',
       'Den',
       '19940202-9999',
       1);

INSERT INTO Persons
VALUES('Den',
       '19960708-8888',
       'Thera Cloone',
       'Den',
       'Ros',
       10 );

UPDATE Persons SET  locationcountry = 'Den', locationarea = 'Kob'
WHERE country = 'Den'
  AND personnummer = '19960708-8888';

--DELETE FROM Persons
--WHERE country ='Den' AND personnummer ='19940202-4815'
