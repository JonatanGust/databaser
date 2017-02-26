--"Test" every table test trigger no cost for building road as GOV.

INSERT  INTO  Countries  VALUES(' ');
INSERT  INTO  Countries  VALUES('Swe');
INSERT  INTO  Areas  VALUES( 'Swe', 'Gbg',491630);
INSERT  INTO  Persons  VALUES(' ', ' ', 'The government', 'Swe', 'Gbg', 100000000000);
INSERT INTO Cities VALUES( 'Swe','Gbg',0);
INSERT  INTO  Areas  VALUES( 'Swe','Sth', 491630*2);
INSERT INTO Cities VALUES( 'Swe','Sth',0);
INSERT INTO ROADS
VALUES('Swe',
       'Gbg',
       'Swe',
       'Sth',
       ' ',
       ' ');
