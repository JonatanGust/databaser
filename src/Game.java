/* This is the driving engine of the program. It parses the command-line
 * arguments and calls the appropriate methods in the other classes.
 *
 * You should edit this file in three ways:
 * 1) Insert your database username and password in the proper places.
 * 2) Implement the generation of the world by reading the world file.
 * 3) Implement the three functions showPossibleMoves, showPlayerAssets
 *    and showScores.
 */

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.sql.*;
import java.util.ArrayList;
import java.util.Properties;

public class Game
{
    public class Player
    {
        String playername;
        String personnummer;
        String country;
        String startingArea;

        public Player (String name, String nr, String cntry, String startingArea) {
            this.playername = name;
            this.personnummer = nr;
            this.country = cntry;
            this.startingArea = startingArea;
        }
    }

    String USERNAME = "tda357_046";
    String PASSWORD = "zrwHt3Xn";

    /* Print command optionssetup.
    * /!\ you don't need to change this function! */
    public void optionssetup() {
        System.out.println();
        System.out.println("Setup-Options:");
        System.out.println("		n[ew player] <player name> <personnummer> <country>");
        System.out.println("		d[one]");
        System.out.println();
    }

    /* Print command options.
    * /!\ you don't need to change this function! */
    public void options() {
        System.out.println("\nOptions:");
        System.out.println("    n[ext moves] [area name] [area country]");
        System.out.println("    l[ist properties] [player number] [player country]");
        System.out.println("    s[cores]");
        System.out.println("    r[efund] <area1 name> <area1 country> [area2 name] [area2 country]");
        System.out.println("    b[uy] [name] <area1 name> <area1 country> [area2 name] [area2 country]");
        System.out.println("    m[ove] <area1 name> <area1 country>");
        System.out.println("    p[layers]");
        System.out.println("    q[uit move]");
        System.out.println("    [...] is optional\n");
    }
    private void printTable (ResultSet resultSet) throws SQLException{
        try {
            StringBuilder stringBuilder = new StringBuilder();
            int columnCount = resultSet.getMetaData().getColumnCount();
            while (resultSet.next()) {
                for (int i = 0; i < columnCount;) {
                    stringBuilder.append("\t\t");
                    if(resultSet.getString(i + 1) != null)stringBuilder.append(resultSet.getString(i + 1));
                    else stringBuilder.append(resultSet.getInt(i + 1));
                    if (++i < columnCount) stringBuilder.append("\t\t|");
                }
                stringBuilder.append("\r\n");
            }
            stringBuilder.append("\r\nhellu\r\n");
            System.out.println(stringBuilder.toString());
            //String resultSetAsString = stringBuilder.toString();

        } catch (SQLException e){
            System.out.println("Print table fail!");
            System.out.println(e.getMessage());
            throw e;
        }

    }

    /* Given a town name, country and population, this function should try to insert an area and a town (and possibly
       also a country) for the given attributes. */
    void insertTown(Connection conn, String name, String country, String population) throws SQLException  {
        // TODO Your implementation here

        try {
            PreparedStatement statement;
            try{
                statement = conn.prepareStatement("INSERT INTO Countries  VALUES (?)");
                statement.setString(1, country);
                statement.executeUpdate();
            } catch (SQLException e){
                //If fail, country allready in Countries
                System.out.println(e.getMessage());
            }

            //Both inserts should work, otherwise that area/town already exists

            statement = conn.prepareStatement("INSERT INTO Areas  VALUES (?, ?, cast(? as NUMERIC))");
            statement.setString(1, country);
            statement.setString(2, name);
            statement.setString(3, population);
            statement.executeUpdate();

            statement = conn.prepareStatement("INSERT INTO Town  VALUES (?, ?)");
            statement.setString(1, country);
            statement.setString(2, name);
            statement.executeUpdate();
            statement.close();
        } catch (SQLException e) {
            //throw e; //TODO this should be ok?
            System.out.println(e.getMessage());
        }

        // TODO TO HERE
    }

    /* Given a city name, country and population, this function should try to insert an area and a city (and possibly
       also a country) for the given attributes. The city visitbonus should be set to 0. */
    void insertCity(Connection conn, String name, String country, String population) throws SQLException {
        // TODO: Your implementation here, visitbonus??

        try {
            PreparedStatement statement;
            try {
                statement = conn.prepareStatement("INSERT INTO Countries  VALUES ( ? )");
                statement.setString(1, country);
                statement.executeUpdate();
            } catch (SQLException e) {
                //Country allready exists
                System.out.println(e.getMessage());
            }

            statement = conn.prepareStatement("INSERT INTO Areas VALUES (?, ?, cast(? as NUMERIC))");
            statement.setString(1, country);
            statement.setString(2, name);
            statement.setString(3, population);
            statement.executeUpdate();

            statement = conn.prepareStatement("INSERT INTO Cities VALUES (?, ?, cast(? as NUMERIC))");
            statement.setString(1, country);
            statement.setString(2, name);
            statement.setString(3, "0");
            statement.executeUpdate();

            statement.close();

        } catch (SQLException e) {
            //throw e;//TODO this should be ok?
            System.out.println(e.getMessage());
        }

        // TODO TO HERE
    }

    /* Given two areas, this function should try to insert a government owned road with tax 0 between these two areas. */
    void insertRoad(Connection conn, String area1, String country1, String area2, String country2) throws SQLException {
        // TODO: Your implementation here
        try {
            PreparedStatement statement;
            try {
                statement = conn.prepareStatement("INSERT INTO Countries  VALUES (?)");
                statement.setString(1, country1);
                statement.executeUpdate();
            } catch (SQLException e) {
                //is oke
                System.out.println(e.getMessage());
            }
            try {
                statement = conn.prepareStatement("INSERT INTO Countries  VALUES (?)");
                statement.setString(1, country2);
                statement.executeUpdate();
            } catch (SQLException e) {
                //is oke
                System.out.println(e.getMessage());
            }
            try {
                statement = conn.prepareStatement("INSERT INTO Areas  VALUES (?, ?, cast(? as NUMERIC))");
                statement.setString(1, country1);
                statement.setString(2, area1);
                statement.setString(3, "0");
                statement.executeUpdate();
            } catch (SQLException e) {
                //is oke
                System.out.println(e.getMessage());
            }
            try {
                statement = conn.prepareStatement("INSERT INTO Areas  VALUES (?, ?, cast(? as NUMERIC))");
                statement.setString(1, country2);
                statement.setString(2, area2);
                statement.setString(3, "0");
                statement.executeUpdate();
            } catch (SQLException e) {
                //is oke
                System.out.println(e.getMessage());
            }


            statement = conn.prepareStatement("INSERT INTO Roads " +
                    "  VALUES (?, ?, ?, ?, ?, ?, cast(? as NUMERIC))"); //cast(? as NUMERIC), cast(? as NUMERIC))");
            statement.setString(1, country1);
            statement.setString(2, area1);
            statement.setString(3, country2);
            statement.setString(4, area2);
            statement.setString(5, "");//GOV. owned
            statement.setString(6, "");
            statement.setString(7, "0");//0 tax
            statement.executeUpdate();
            statement.close();
        } catch (SQLException e) {
            //throw e;//TODO this should be ok?
            System.out.println(e.getMessage());
        }


        // TODO TO HERE
    }

    /* Given a player, this function should return the area name of the player's current location. */
    String getCurrentArea(Connection conn, Player person) throws SQLException {
        // TODO: Your implementation here
        try {
            PreparedStatement statement = conn.prepareStatement("SELECT locationarea FROM Persons WHERE country = ? AND personnummer = ?");
            statement.setString(1, person.country);
            statement.setString(2, person.personnummer);
            ResultSet resultset = statement.executeQuery();
            //printTable(resultset);//return?
            resultset.next();
            String anwser = resultset.getString(1);
            resultset.close();
            statement.close();
            return anwser;
        } catch (SQLException e) {
            //throw e;//TODO this should be ok?
            System.out.println(e.getMessage());
        }

        /*
        String query = "WITH R1 AS (SELECT CLASS, (numGuns * bore ^ 3) AS firepower FROM classes), " +
                "R2 AS (SELECT min(firepower) minimum FROM R1) SELECT CLASS FROM R1 " +
                "WHERE firepower = (SELECT minimum FROM R2)";
        */
        return null;
        // TODO TO HERE
    }

    /* Given a player, this function should return the country name of the player's current location. */
    String getCurrentCountry(Connection conn, Player person) throws SQLException {
        // TODO: Your implementation here
        try {
            PreparedStatement statement = conn.prepareStatement("SELECT locationcountry FROM Persons WHERE country = ? AND personnummer = ?");
            statement.setString(1, person.country);
            statement.setString(2, person.personnummer);
            ResultSet resultSet = statement.executeQuery();
            //printTable(resultSet);//return?
            resultSet.next();
            String anwser = resultSet.getString(1);
            resultSet.close();
            statement.close();
            return anwser;
        } catch (SQLException e){
            //throw e;//TODO this should be ok?
            System.out.println(e.getMessage());
        }
        // TODO TO HERE
        return null;
    }

    /* Given a player, this function should try to insert a table entry in persons for this player and return 1 in
       case of a success and 0 otherwise. The location should be random and the budget should be 1000. */
    int createPlayer(Connection conn, Player person) throws SQLException {
        // TODO: Your implementation here

        try{
            PreparedStatement statement;
            statement = conn.prepareStatement("INSERT INTO Persons " +
                    " VALUES (?, ?, ?, ?, ?, cast(? AS NUMERIC))");
            statement.setString(1, person.country);
            statement.setString(2, person.personnummer);
            statement.setString(3, person.playername);
            statement.setString(4, person.country);
            statement.setString(5, person.startingArea);
            statement.setInt(6, 1000);
            statement.executeUpdate();
            statement.close();
            return 1;
        } catch (SQLException e){
            System.out.println(e.getMessage());
            return 0;
            //is oke
        }

        // TODO TO HERE
    }

    /* Given a player and an area name and country name, this function
     * sould show all directly-reachable destinations for the player from the
     * area from the arguments.
     * The output should include area names, country names and the associated road-taxes
      */
    void getNextMoves(Connection conn, Player person, String area, String country) throws SQLException {
        // TODO: Your implementation here
        try {
            PreparedStatement statement;
        /*statement = conn.prepareStatement(
                "SELECT destcountry, destarea, roadtax FROM NextMoves WHERE personcountry = ? AND personnummer = ? " );*/
            statement = conn.prepareStatement(
                    "SELECT destcountry, destarea, MIN(roadtax) AS roadtax FROM ( " +
                            " ( " +
                            " SELECT ( fromcountry AS destcountry, fromarea AS destarea, roadtax AS roadtax ) FROM Roads" +
                            " WHERE tocountry = ? AND toarea = ? AND roadtax <= (SELECT budget FROM Persons WHERE country = ? AND personnummer = ?) " +
                            " ) " +
                            " UNION " +
                            " ( " +
                            " SELECT ( tocountry AS destcountry, toarea AS destarea, roadtax AS roadtax ) FROM Roads" +
                            " WHERE fromcountry = ? AND fromarea = ? AND roadtax <= (SELECT budget FROM Persons WHERE country = ? AND personnummer = ?) " +
                            " ) " +
                            " UNION " +
                            " ( " +
                            " SELECT ( fromcountry AS destcountry, fromarea AS destarea, 0 AS roadtax ) FROM Roads" +
                            " WHERE tocountry = ? AND toarea = ? AND ownercountry = ? AND ownerpersonnummer = ?" +
                            " ) " +
                            " UNION " +
                            " ( " +
                            " SELECT ( tocountry AS destcountry, toarea AS destarea, 0 AS roadtax ) FROM Roads" +
                            " WHERE fromcountry = ? AND fromarea = ? AND ownercountry = ? AND ownerpersonnummer = ? " +
                            " ) " +
                            " ) AS huehue" +
                            " GROUP BY destcountry, destarea" );
            statement.setString(1, country);
            statement.setString(2, area);
            statement.setString(3, person.country);
            statement.setString(4, person.personnummer);
            statement.setString(5, country);
            statement.setString(6, area);
            statement.setString(7, person.country);
            statement.setString(8, person.personnummer);
            statement.setString(9, country);
            statement.setString(10, area);
            statement.setString(11, person.country);
            statement.setString(12, person.personnummer);
            statement.setString(13, country);
            statement.setString(14, area);
            statement.setString(15, person.country);
            statement.setString(16, person.personnummer);
            ResultSet resultset = statement.executeQuery();
        /*statement.setString(1, person.country);
        statement.setString(2, person.personnummer);*/
            printTable(resultset);
            resultset.close();
            statement.close();
        } catch (SQLException e){
            //throw e;//TODO this should be ok?
            System.out.println(e.getMessage());
        }

        // TODO TO HERE
    }

    /* Given a player, this function sould show all directly-reachable destinations for the player from the player's
       current location. The output should include area names, country names and the associated road-taxes. */
    void getNextMoves(Connection conn, Player person) throws SQLException {
        // TODO: Your implementation here
        // hint: Use your implementation of the overloaded getNextMoves function
        try {
            PreparedStatement statement;
            statement = conn.prepareStatement(
                    "SELECT destcountry, destarea, cost FROM NextMoves WHERE personcountry = ? AND personnummer = ?" );
            statement.setString(1, person.country);
            statement.setString(2, person.personnummer);
            ResultSet resultset = statement.executeQuery();
            printTable(resultset);
            resultset.close();
            statement.close();
        } catch (SQLException e) {
            //throw e;//TODO this should be ok?
            System.out.println(e.getMessage());
        }

        // TODO TO HERE
    }

    /* Given a personnummer and a country, this function should list all properties (roads and hotels) of the person
       that is identified by the tuple of personnummer and country. */
    void listProperties(Connection conn, String personnummer, String country) {
        // TODO: Your implementation here
        try {
            PreparedStatement statement;
            statement = conn.prepareStatement(
                    "SELECT isHotel, locationCountry1, locationArea1, locationCountry2, locationArea2, cost FROM" +
                            "( " +
                                "( " +
                                "SELECT  true AS isHotel, locationcountry AS locationCountry1, locationname AS locationArea1, null AS locationCountry2, " +
                                " null AS locationArea2, 0 AS cost  FROM Hotels WHERE ownercountry = ? AND ownerpersonnummer = ? " +
                                ")" +
                                "UNION" +
                                "(" +
                                "SELECT  false AS isHotel, tocountry AS locationCountry1, toarea AS locationArea1, fromcountry AS locationCountry2, " +
                                " fromarea AS locationArea2, roadtax AS cost  FROM Roads WHERE ownercountry = ? AND ownerpersonnummer = ? " +
                                ")" +
                            " ) as huehue"   );
            statement.setString(1, country);
            statement.setString(2, personnummer);
            statement.setString(3, country);
            statement.setString(4, personnummer);
            ResultSet resultset = statement.executeQuery();
            printTable(resultset);
            resultset.close();
            statement.close();
        } catch (SQLException e) {
            //throw e;//TODO this should be ok?
            System.out.println(e.getMessage());
        }

        // TODO TO HERE
    }

    /* Given a player, this function should list all properties of the player. */
    void listProperties(Connection conn, Player person) throws SQLException {
        // TODO: Your implementation here
        // hint: Use your implementation of the overlaoded listProperties function
        listProperties(conn, person.personnummer, person.country);
        // TODO TO HERE
    }

    /* This function should print the budget, assets and refund values for all players. */
    void showScores(Connection conn) throws SQLException {
        // TODO: Your implementation herePreparedStatement statement;
        try {
            PreparedStatement statement;
            statement = conn.prepareStatement("SELECT * FROM AssetSummary" );
            ResultSet resultset = statement.executeQuery();
            printTable(resultset);
            resultset.close();
            statement.close();
        } catch (SQLException e) {
            //throw e;//TODO this should be ok?
            System.out.println(e.getMessage());
        }
        // TODO TO HERE
    }

    /* Given a player, a from area and a to area, this function should try to sell the road between these areas owned
       by the player and return 1 in case of a success and 0 otherwise. */
    int sellRoad(Connection conn, Player person, String area1, String country1, String area2, String country2) throws SQLException {
        // TODO: Your implementation here
        try{
            PreparedStatement statement;
            statement = conn.prepareStatement("DELETE FROM Roads WHERE ownerpersonnummer = ? AND ownercountry = ? " +
                    " AND fromcountry = ? AND fromarea = ? AND tocountry = ? AND toarea = ?");
            statement.setString(1, person.country);
            statement.setString(2, person.personnummer);
            statement.setString(3, country1);
            statement.setString(4, area1);
            statement.setString(5, country2);
            statement.setString(6, area2);
            statement.executeUpdate();
            //How much does a road sell for????
            statement = conn.prepareStatement("UPDATE Persons SET budget = (budget + getval('roadprice'))  WHERE personnummer = ? AND country = ? " );
            statement.setString(1, person.country);
            statement.setString(2, person.personnummer);
            statement.executeUpdate();

            statement.close();
            return 1;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
            return 0;
        }
        // TODO TO HERE
    }

    /* Given a player and a city, this function should try to sell the hotel in this city owned by the player and
       return 1 in case of a success and 0 otherwise. */
    int sellHotel(Connection conn, Player person, String city, String country) throws SQLException {
        // TODO: Your implementation here
        try{
            PreparedStatement statement;
            statement = conn.prepareStatement("DELETE FROM Hotels WHERE ownerpersonnummer = ? AND ownercountry = ? " +
                    " AND locationcountry = ? AND locationname = ? ");
            statement.setString(1, person.country);
            statement.setString(2, person.personnummer);
            statement.setString(3, country);
            statement.setString(4, city);
            statement.executeUpdate();
            statement.close();
            return 1;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
            return 0;
        }
        // TODO TO HERE
    }

    /* Given a player, a from area and a to area, this function should try to buy a road between these areas owned by
       the player and return 1 in case of a success and 0 otherwise. */
    int buyRoad(Connection conn, Player person, String area1, String country1, String area2, String country2) throws SQLException {
        // TODO: Your implementation here
        try{
            PreparedStatement statement;
            statement = conn.prepareStatement("INSERT INTO Roads  " +
                    "VALUES( ?, ?, ?, ?, ?, ?)");
            statement.setString(1, country1);
            statement.setString(2, area1);
            statement.setString(3, country2);
            statement.setString(4, area2);
            statement.setString(5, person.country);
            statement.setString(6, person.personnummer);
            statement.executeUpdate();
            statement.close();
            return 1;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
            return 0;
        }
        // TODO TO HERE
    }

    /* Given a player and a city, this function should try to buy a hotel in this city owned by the player and return
       1 in case of a success and 0 otherwise. */
    int buyHotel(Connection conn, Player person, String name, String city, String country) throws SQLException {
        // TODO: Your implementation here
        try{
            PreparedStatement statement;
            statement = conn.prepareStatement("INSERT INTO Hotels  " +
                    "VALUES( ?, ?, ?, ?, ?)");
            statement.setString(1, name);
            statement.setString(2, country);
            statement.setString(3, city);
            statement.setString(4, person.country);
            statement.setString(5, person.personnummer);
            statement.executeUpdate();
            statement.close();
            return 1;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
            return 0;
        }
        // TODO TO HERE
    }

    /* Given a player and a new location, this function should try to update the players location and return 1 in case
       of a success and 0 otherwise. */
    int changeLocation(Connection conn, Player person, String area, String country) throws SQLException {
        // TODO: Your implementation here
        try{
            PreparedStatement statement;
            statement = conn.prepareStatement(" UPDATE Persons SET  locationcountry = ? , locationarea = ?  " +
                    " WHERE country = ? AND personnummer = ?");
            statement.setString(1, country);
            statement.setString(2, area);
            statement.setString(3, person.country);
            statement.setString(4, person.personnummer);
            statement.executeUpdate();
            statement.close();
            return 1;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
            return 0;
        }
        // TODO TO HERE
    }

    /* This function should add the visitbonus of 1000 to a random city */
    void setVisitingBonus(Connection conn) throws SQLException {
        // TODO: Your implementation here
        try{
            PreparedStatement statement;
            statement = conn.prepareStatement("UPDATE Cities SET  visitbonus = visitbonus + 1000 LIMIT 1");
            statement.executeUpdate();
            statement.close();
        } catch (SQLException e) {
            //throw e;//TODO this should be ok?
            System.out.println(e.getMessage());
        }
        // TODO TO HERE
    }

    /* This function should print the winner of the game based on the currently highest budget. */
    void announceWinner(Connection conn) throws SQLException {
        // TODO: Your implementation here
        try {
            PreparedStatement statement;
            statement = conn.prepareStatement("SELECT * FROM Persons WHERE budget = ( SELECT MAX(budget) FROM Persons ) " );
            ResultSet resultset = statement.executeQuery();
            printTable(resultset);
            resultset.close();
            statement.close();
        } catch (SQLException e) {
            //throw e;//TODO this should be ok?
            System.out.println(e.getMessage());
        }
        // TODO TO HERE
    }

    void play (String worldfile) throws IOException {

        // Read username and password from config.cfg
        try {
            BufferedReader nf = new BufferedReader(new FileReader("config.cfg"));
            String line;
            if ((line = nf.readLine()) != null) {
                USERNAME = line;
            }
            if ((line = nf.readLine()) != null) {
                PASSWORD = line;
            }
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }

        if (USERNAME.equals("USERNAME") || PASSWORD.equals("PASSWORD")) {
            System.out.println("CONFIG FILE HAS WRONG FORMAT");
            return;
        }

        try {
            try {
                Class.forName("org.postgresql.Driver");
            } catch (Exception e) {
                System.out.println(e.getMessage());
            }
            String url = "jdbc:postgresql://ate.ita.chalmers.se/";
            Properties props = new Properties();
            props.setProperty("user",USERNAME);
            props.setProperty("password",PASSWORD);

            final Connection conn = DriverManager.getConnection(url, props);

			/* This block creates the government entry and the necessary country and area for that. */
            try {
                PreparedStatement statement = conn.prepareStatement("INSERT INTO Countries  VALUES (?)");
                statement.setString(1, "");
                statement.executeUpdate();
                statement = conn.prepareStatement("INSERT INTO Areas  VALUES (?, ?, cast(? as INT))");
                statement.setString(1, "");
                statement.setString(2, "");
                statement.setString(3, "1");
                statement.executeUpdate();
                statement = conn.prepareStatement("INSERT INTO Persons  VALUES (?, ?, ?, ?, ?, cast(? as NUMERIC))");
                statement.setString(1, "");
                statement.setString(2, "");
                statement.setString(3, "Government");
                statement.setString(4, "");
                statement.setString(5, "");
                statement.setString(6, "0");
                statement.executeUpdate();
            } catch (SQLException e) {
                System.out.println(e.getMessage());
            }

            // Initialize the database from the worldfile
            try {
                BufferedReader br = new BufferedReader(new FileReader(worldfile));
                String line;
                while ((line = br.readLine()) != null) {
                    String[] cmd = line.split(" +");
                    if ("ROAD".equals(cmd[0]) && (cmd.length == 5)) {
                        insertRoad(conn, cmd[1], cmd[2], cmd[3], cmd[4]);
                    } else if ("TOWN".equals(cmd[0]) && (cmd.length == 4)) {
						/* Create an area and a town entry in the database */
                        insertTown(conn, cmd[1], cmd[2], cmd[3]);
                    } else if ("CITY".equals(cmd[0]) && (cmd.length == 4)) {
						/* Create an area and a city entry in the database */
                        insertCity(conn, cmd[1], cmd[2], cmd[3]);
                    }
                }
            } catch (Exception e) {
                System.out.println(e.getMessage());
            }

            ArrayList<Player> players = new ArrayList<Player>();

            while(true) {
                optionssetup();
                String mode = readLine("? > ");
                String[] cmd = mode.split(" +");
                cmd[0] = cmd[0].toLowerCase();
                if ("new player".startsWith(cmd[0]) && (cmd.length == 5)) {
                    Player nextplayer = new Player(cmd[1], cmd[2], cmd[3], cmd[4]);
                    if (createPlayer(conn, nextplayer) == 1) {
                        players.add(nextplayer);
                    }
                } else if ("done".startsWith(cmd[0]) && (cmd.length == 1)) {
                    break;
                } else {
                    System.out.println("\nInvalid option.");
                }
            }

            System.out.println("\nGL HF!");
            int roundcounter = 1;
            int maxrounds = 5;
            while(roundcounter <= maxrounds) {
                System.out.println("\nWe are starting the " + roundcounter + ". round!!!");
				/* for each player from the playerlist */
                for (int i = 0; i < players.size(); ++i) {
                    System.out.println("\nIt's your turn " + players.get(i).playername + "!");
                    System.out.println("You are currently located in " + getCurrentArea(conn, players.get(i)) + " (" + getCurrentCountry(conn, players.get(i)) + ")");
                    while (true) {
                        options();
                        String mode = readLine("? > ");
                        String[] cmd = mode.split(" +");
                        cmd[0] = cmd[0].toLowerCase();
                        if ("next moves".startsWith(cmd[0]) && (cmd.length == 1 || cmd.length == 3)) {
							/* Show next moves from a location or current location. Turn continues. */
                            if (cmd.length == 1) {
                                String area = getCurrentArea(conn, players.get(i));
                                String country = getCurrentCountry(conn, players.get(i));
                                getNextMoves(conn, players.get(i));
                            } else {
                                getNextMoves(conn, players.get(i), cmd[1], cmd[2]);
                            }
                        } else if ("list properties".startsWith(cmd[0]) && (cmd.length == 1 || cmd.length == 3)) {
							/* List properties of a player. Can be a specified player
							   or the player himself. Turn continues. */
                            if (cmd.length == 1) {
                                listProperties(conn, players.get(i));
                            } else {
                                listProperties(conn, cmd[1], cmd[2]);
                            }
                        } else if ("scores".startsWith(cmd[0]) && cmd.length == 1) {
							/* Show scores for all players. Turn continues. */
                            showScores(conn);
                        } else if ("players".startsWith(cmd[0]) && cmd.length == 1) {
							/* Show scores for all players. Turn continues. */
                            System.out.println("\nPlayers:");
                            for (int k = 0; k < players.size(); ++k) {
                                System.out.println("\t" + players.get(k).playername + ": " + players.get(k).personnummer + " (" + players.get(k).country + ") ");
                            }
                        } else if ("refund".startsWith(cmd[0]) && (cmd.length == 3 || cmd.length == 5)) {
                            if (cmd.length == 5) {
								/* Sell road from arguments. If no road was sold the turn
								   continues. Otherwise the turn ends. */
                                if (sellRoad(conn, players.get(i), cmd[1], cmd[2], cmd[3], cmd[4]) == 1) {
                                    break;
                                } else {
                                    System.out.println("\nTry something else.");
                                }
                            } else {
								/* Sell hotel from arguments. If no hotel was sold the turn
								   continues. Otherwise the turn ends. */
                                if (sellHotel(conn, players.get(i), cmd[1], cmd[2]) == 1) {
                                    break;
                                } else {
                                    System.out.println("\nTry something else.");
                                }
                            }
                        } else if ("buy".startsWith(cmd[0]) && (cmd.length == 4 || cmd.length == 5)) {
                            if (cmd.length == 5) {
								/* Buy road from arguments. If no road was bought the turn
								   continues. Otherwise the turn ends. */
                                if (buyRoad(conn, players.get(i), cmd[1], cmd[2], cmd[3], cmd[4]) == 1) {
                                    break;
                                } else {
                                    System.out.println("\nTry something else.");
                                }
                            } else {
								/* Buy hotel from arguments. If no hotel was bought the turn
								   continues. Otherwise the turn ends. */
                                if (buyHotel(conn, players.get(i), cmd[1], cmd[2], cmd[3]) == 1) {
                                    break;
                                } else {
                                    System.out.println("\nTry something else.");
                                }
                            }
                        } else if ("move".startsWith(cmd[0]) && cmd.length == 3) {
							/* Change the location of the player to the area from the arguments.
							   If the move was legal the turn ends. Otherwise the turn continues. */
                            if (changeLocation(conn, players.get(i), cmd[1], cmd[2]) == 1) {
                                break;
                            } else {
                                System.out.println("\nTry something else.");
                            }
                        } else if ("quit".startsWith(cmd[0]) && cmd.length == 1) {
							/* End the move of the player without any action */
                            break;
                        } else {
                            System.out.println("\nYou chose an invalid option. Try again.");
                        }
                    }
                }
                setVisitingBonus(conn);
                ++roundcounter;
            }
            announceWinner(conn);
            System.out.println("\nGG!\n");

            conn.close();
        } catch (SQLException e) {
            System.err.println(e);
            System.exit(2);
        }
    }

    private String readLine(String s) throws IOException {
        System.out.print(s);
        BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(System.in));
        char c;
        StringBuilder stringBuilder = new StringBuilder();
        do {
            c = (char) bufferedReader.read();
            stringBuilder.append(c);
        } while(String.valueOf(c).matches(".")); // Without the DOTALL switch, the dot in a java regex matches all characters except newlines

        System.out.println("");
        stringBuilder.deleteCharAt(stringBuilder.length()-1);

        return stringBuilder.toString();
    }

    /* main: parses the input commands.
     * /!\ You don't need to change this function! */
    public static void main(String[] args) throws Exception
    {
        String worldfile = args[0];
        Game g = new Game();
        g.play(worldfile);
    }
}
