
-- Test of Hotel Insert when the person already has an hotel in that city -- KLAR!!

INSERT INTO Countries
VALUES('Den');

INSERT INTO Areas
VALUES('Den','Kob',2000000);
INSERT INTO Cities
VALUES('Den','Kob',0);

INSERT INTO Persons
VALUES('Den',
       '19960708-2670',
       'Therese CloneHU',
       'Den',
       'Kob',
       150000 );

INSERT INTO Hotels
VALUES('Hotel KobenClone',
      'Den',
      'Kob',
      'Den',
      '19960708-2670');

INSERT INTO Hotels
VALUES('The KobClone Hotel',
      'Den',
      'Kob',
      'Den',
      '19960708-2670');
