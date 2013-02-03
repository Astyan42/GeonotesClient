<%@page import="java.util.logging.Level"%>
<%@page import="java.util.logging.Logger"%>
<%@page import="javax.naming.NamingException"%>
<%@page import="java.util.Collection"%>
<%@page import="NoteEJB.Note"%>
<%@page import="javax.naming.InitialContext"%>
<%@page import="GeoNotesEJB.GeoNotesRemote"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    GeoNotesRemote bean = (GeoNotesRemote) request.getSession().getAttribute("bean");
    if (bean == null) {
        getServletContext().getRequestDispatcher("/index.jsp").forward(request, response);
    }
%>
<!DOCTYPE xhtml PUBLIC "-//W3C//DTD XHTML 4.01//EN">
<html>
    <head>
        <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
        <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
        <title>Where Am I?</title>
        <link rel="stylesheet" href="/GeoNotesClient/stylesheet.css" type="text/css" media="screen" />
        <script type="text/javascript"
        src="http://maps.google.com/maps/api/js?sensor=true"></script>
        <script type="text/javascript" src="/GeoNotesClient/geometa.js"></script>
        <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.8/jquery.min.js"></script>
        <script type="text/javascript">
            var map;
            var elevator;
            var tabMarqueurs;
            var contentInfo;
            var currentNote;
            
            function initialise() {
                currentNote = 0;
                var latlng = new google.maps.LatLng(-25.363882,131.044922);
                var myOptions = {                    
                    zoom: 4,
                    center: latlng,
                    mapTypeId: google.maps.MapTypeId.TERRAIN,
                    disableDefaultUI: false
                }
                map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);  // Create an ElevationService
                elevator = new google.maps.ElevationService();
                prepareGeolocation();
                doGeolocation();
                tabMarqueurs = new Array();
                contentInfo = new Array();
                initMesNotes();
                google.maps.event.addListener(map, 'click', createNote);
            }
            
            function initMesNotes(){
                $.ajax({
                    async: "false",
                    url: "/GeoNotesClient/servlet/getNotes",
                    data: {mine:"true"},
                    success: function(data){
                        var notes = JSON.parse(data);
                        for(i = 0; i< notes.length;i++){
                            initNote(notes[i].titre, notes[i].longitude, notes[i].latitude, notes[i].altitude, notes[i].id, true);
                        }
                    }
                });
            }
            
            function reinitAll(){
                for (i in tabMarqueurs) {     
                    tabMarqueurs[i].setMap(null);    
                }  
                tabMarqueurs = new Array();
                contentInfo = new Array();
                currentNote = 0;
                initAllNotes();
            }
                
            function reinitMine(){
                for (i in tabMarqueurs) {     
                    tabMarqueurs[i].setMap(null);    
                }  
                currentNote = 0;
                tabMarqueurs = new Array();
                contentInfo = new Array();
                initMesNotes();
            }
            
            function initAllNotes(){
                $.ajax({
                    async: "false",
                    url: "/GeoNotesClient/servlet/getNotes",
                    data: {mine:"false"},
                    success: function(data){
                        var notes = JSON.parse(data);
                        for(i = 0; i< notes.length;i++){
                            initNote(notes[i].titre, notes[i].longitude, notes[i].latitude, notes[i].altitude, notes[i].id, false);
                        }
                    }
                });
            }
            
            function initNote(desc, lon, lat, alt,id,rem){
                latlng = new google.maps.LatLng(lat, lon);
                info = new Array();
                info.push(alt);
                info.push(desc);
                info.push(lon);
                info.push(lat); 
                info.push(id);
                contentInfo.push(info);                                    
                marqueurToPush = new google.maps.Marker({
                    position: latlng,//coordonnée de la position du clic sur la carte
                    map: map//la carte sur laquelle le marqueur doit être affiché
                });
                tabMarqueurs.push(marqueurToPush);
                google.maps.event.addListener(marqueurToPush, 'click', (function(marqueurToPush,currentNote){
                    return function(){
                        contentString =  contentInfo[currentNote][1] +"<br/>longitude : "+ contentInfo[currentNote][2]+"<br/> latitude : "+contentInfo[currentNote][3]+"<br/>altitude : "+ contentInfo[currentNote][0] +"<br/> ";
                        var infowindow = new google.maps.InfoWindow({
                            content: contentString
                        });
                        infowindow.open(map,marqueurToPush);
                    }
                })(marqueurToPush,currentNote));
                if(rem == true){
                    google.maps.event.addListener(marqueurToPush, 'rightclick', (function(marqueurToPush,currentNote){
                        return function(){
                            $.post("/GeoNotesClient/servlet/rmNote",{id:contentInfo[currentNote][4]},function(data){marqueurToPush.setMap(null);
                                currentNote--;});
                                
                        }
                    })(marqueurToPush,currentNote));
                }
                currentNote++;
            }
            
            function createNote(event){
                // Event de création de la note
                latitudeNote = event.latLng.lat();
                longitudeNote = event.latLng.lng();
                var locations = [];
                var altitude;
                    
                // Retrieve the clicked location and push it on the array
                var clickedLocation = event.latLng;
                locations.push(clickedLocation);

                // Create a LocationElevationRequest object using the array's one value
                var positionalRequest = {
                    'locations': locations
                }

                // Initiate the location request
                elevator.getElevationForLocations(positionalRequest, function(results, status) {
                    if (status == google.maps.ElevationStatus.OK) {
                        // Retrieve the first result
                        if (results[0]) {                                    
                            altitude = results[0].elevation;
                            var titre=prompt("Donnez un nom à votre note","");
                            if(titre != null){
                                info = new Array();
                                info.push(altitude);
                                info.push(titre);
                                info.push(longitudeNote);
                                info.push(latitudeNote);
                                $.post("/GeoNotesClient/servlet/ajoutNote",{longitude : longitudeNote, latitude : latitudeNote, altitude : altitude, description : titre},function(data){
                                    info.push(data);
                                    contentInfo.push(info);
                                    marqueurToPush = new google.maps.Marker({
                                        position: event.latLng,//coordonnée de la position du clic sur la carte
                                        map: map//la carte sur laquelle le marqueur doit être affiché
                                    });
                                    tabMarqueurs.push(marqueurToPush);
                                    google.maps.event.addListener(marqueurToPush, 'click', (function(marqueurToPush,currentNote){
                                        return function(){
                                            contentString =  contentInfo[currentNote][1] +"<br/>longitude : "+ contentInfo[currentNote][2]+"<br/> latitude : "+contentInfo[currentNote][3]+"<br/>altitude : "+ contentInfo[currentNote][0] +"<br/> ";
                                            var infowindow = new google.maps.InfoWindow({
                                                content: contentString
                                            });
                                            infowindow.open(map,marqueurToPush);
                                        }
                                    })(marqueurToPush,currentNote));
                                    google.maps.event.addListener(marqueurToPush, 'rightclick', (function(marqueurToPush,currentNote){
                                        return function(){
                                            $.post("/GeoNotesClient/servlet/rmNote",{id:contentInfo[currentNote][4]},function(data){marqueurToPush.setMap(null);
                                                currentNote--;});
                                        }
                                    })(marqueurToPush,currentNote));
                                    currentNote++;
                                });
                                

                            }
                        } else {
                            alert("No results found");
                        }
                    } else {
                        alert("Elevation service failed due to: " + status);
                    }
                });
                

            }
            
            function doGeolocation() {
                if (navigator.geolocation) {
                    navigator.geolocation.getCurrentPosition(positionSuccess, positionError);
                } else {
                    positionError(-1);
                }
            }

            function positionError(err) {
                var msg;
                switch(err.code) {
                    case err.UNKNOWN_ERROR:
                        msg = "Unable to find your location";
                        break;
                    case err.PERMISSION_DENINED:
                        msg = "Permission denied in finding your location";
                        break;
                    case err.POSITION_UNAVAILABLE:
                        msg = "Your location is currently unknown";
                        break;
                    case err.BREAK:
                        msg = "Attempt to find location took too long";
                        break;
                    default:
                        msg = "Location detection not supported in browser";
                }
                alert(msg);
            }

            function positionSuccess(position) {
                // Centre the map on the new location
                var coords = position.coords || position.coordinate || position;
                var latLng = new google.maps.LatLng(coords.latitude, coords.longitude);
                map.setCenter(latLng);
                map.setZoom(20);
            }

            function contains(array, item) {
                for (var i = 0, I = array.length; i < I; ++i) {
                    if (array[i] == item) return true;
                }
                return false;
            }


        </script>
    </head>
    <body onload="initialise()">        
        <div id="map_canvas"></div>
        <div id="titre" class ="lightbox"><h2>ajout de notes</h2></div>
        <div id="info" class="lightbox">
            <table>
                <tr>
                    <td><a href="#" onclick="reinitMine()">Voir mes notes</a></td>
                </tr> <tr>
                    <td><a href="#" onclick="reinitAll()">Voir toutes les notes</a></td>
                </tr><tr>
                    <td><a href="/GeoNotesClient/updateNote.jsp"> Modifier une note </a></td>
                </tr><tr>
                    <td><a href="/GeoNotesClient/createParcours.jsp">Créer un parcours</a></td>                    
                </tr><tr>
                    <td><a href="/GeoNotesClient/showParcours.jsp"> Voir les parcours </a></td>
                </tr>
                <tr>
                    <td>
                        <form name="logout" action ="/GeoNotesClient/servlet/logout" method="post">            
                            <input type="submit" name="valider" value="Deconnexion">
                        </form>
                    </td>
                </tr>
            </table>
        </div>
        <div id="legende" class="lightBox">
            <br/>
            <h5>Note</h5>
            <ul>
                <li>clic gauche : afficher les informations</li>
                <li>clic droit : supprimer les informations</li>
            </ul>
            <h5>Map</h5>
            <ul>
                <li>clic gauche : ajouter une note</li>
            </ul>
        </div>
    </body>
</html>
