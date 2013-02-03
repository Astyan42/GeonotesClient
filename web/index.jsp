<%-- 
    Document   : index
    Created on : 8 janv. 2013, 16:48:28
    Author     : Michael
--%>

<%@page import="GeoNotesEJB.GeoNotesRemote"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>GeoNotes</title>
    </head>
    <body>
        <%
            if ((request.getAttribute("isLogged") == null)) {
                getServletContext().getRequestDispatcher("/servlet/isLog").forward(request, response);
            }
        %>
        <h1>Bienvenue sur GeoNotes</h1>
        <h2>Se connecter</h2>
        <form name="log" action="/GeoNotesClient/servlet/log" method="post">
            Login : <input type="text" name="login"><br/>
            Password : <input type="password" name="password"><br/>
            <input type="submit" name="valider" value="Se connecter">
        </form>
        <h2>S'enregistrer</h2>
        <form name="register" action="/GeoNotesClient/servlet/register" method="post">
            Login : <input type="text" name="registerLogin"><br/>
            Password : <input type="password" name="registerPassword"><br/>
            <input type="submit" name="valider" value="S'enregistrer">
        </form>
    </body>
</html>
