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
            var tabPolyline;
            var line;
            var tabLines;            
            var directionsDisplay;
            var directionsR = new Array();
            var directionsServiceM = function(start, end, waypoints, color){
                directionsService = new google.maps.DirectionsService;
                return (function (start, end, waypoints) {
                    waypts=[];
                    for(k in waypoints){
                        waypts.push({location:waypoints[k],stopover:true});
                    }
                    directionsService.route({
                        origin: start,
                        destination: end,
                        waypoints : waypts,
                        travelMode: google.maps.DirectionsTravelMode.WALKING
                    }, function(result, status) {
                        renderDirections(result, status, color);
                    });
                })(start, end, waypoints, color);
            };
            
            function renderDirections(result,status, color) {
                if(status == google.maps.DirectionsStatus.OK){
                    var directionsRenderer = new google.maps.DirectionsRenderer({polylineOptions:{strokeColor:color},suppressMarkers: true});
                    directionsRenderer.setMap(map);
                    directionsRenderer.setPanel(parcours);
                    directionsRenderer.setDirections(result);
                    directionsR.push(directionsRenderer);
                }
                else if (status == google.maps.DirectionsStatus.INVALID_REQUEST){
                    alert("INVALID_REQUEST !");
                }
                else if (status == google.maps.DirectionsStatus.MAX_WAYPOINTS_EXCEEDED){
                    alert("MAX_WAYPOINTS_EXCEEDED !");
                }
                else if (status == google.maps.DirectionsStatus.NOT_FOUND){
                    alert("NOT_FOUND !");
                }
                else if (status == google.maps.DirectionsStatus.OVER_QUERY_LIMIT){
                    alert("OVER_QUERY_LIMIT !");
                }
                else if (status == google.maps.DirectionsStatus.REQUEST_DENIED){
                    alert("REQUEST_DENIED !");
                }
                else if (status == google.maps.DirectionsStatus.UNKNOWN_ERROR){
                    alert("UNKNOWN_ERROR !");
                }
                else if (status == google.maps.DirectionsStatus.ZERO_RESULTS){
                    alert("ZERO_RESULTS");
                }
            }
            function initialise() {
                document.getElementById("parcours").style.visibility = "hidden";
                directionsDisplay = new google.maps.DirectionsRenderer( {
                    draggable: false,
                    suppressMarkers: false
                });
                currentNote = 0;
                var latlng = new google.maps.LatLng(-25.363882,131.044922);
                var myOptions = {                    
                    zoom: 4,
                    center: latlng,
                    mapTypeId: google.maps.MapTypeId.TERRAIN,
                    disableDefaultUI: false
                }
                map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);  
                elevator = new google.maps.ElevationService();
                prepareGeolocation();
                doGeolocation();
                tabMarqueurs = new Array();
                contentInfo = new Array();
                tabPolyline = new Array();
                tabLines = new Array();
                line = new google.maps.Polyline(
                {   
                    map:map,
                    strokeColor:"#0000FF",
                    strokeOpacity:0.8,
                    strokeWeight:2
                });
                initMesParcours();
            }
            
            function initMesParcours(){
                $.ajax({
                    async: "false",
                    url: "/GeoNotesClient/servlet/getParcours",
                    data: {mine:"true"},
                    success: function(data){
                        var parcours = JSON.parse(data);
                        for(i = 0; i< parcours.length;i++){
                            latlong = new Array();       
                            for(j = 0; j<parcours[i].notes.length; j++){
                                initNote(parcours[i].notes[j].titre, parcours[i].notes[j].longitude, parcours[i].notes[j].latitude, parcours[i].notes[j].altitude, parcours[i].notes[j].id, true);
                                latlong.push(new google.maps.LatLng(parcours[i].notes[j].latitude,parcours[i].notes[j].longitude));
                            }               
                            parcoursLine = new google.maps.Polyline(
                            {   
                                map:map,
                                path:latlong,
                                strokeColor:get_random_color(),
                                strokeOpacity:0.8,
                                strokeWeight:2
                            });
                            google.maps.event.addListener(parcoursLine, 'click', (function(i){
                                return function(){
                                    reinitParticular(parcours[i].id);
                                }
                            })(i));  
                            google.maps.event.addListener(parcoursLine, 'rightclick', (function(parcoursLine,i){
                                return function(){
                                    $.post("/GeoNotesClient/servlet/deleteParcours",{id:parcours[i].id},function(data){parcoursLine.setMap(null);});
                                }
                            })(parcoursLine,i));
                            tabLines.push(parcoursLine);
                        }
                    }
                });
            }
            
            function reinitParticular(id){
                for (i in tabMarqueurs) {     
                    tabMarqueurs[i].setMap(null);    
                }  
                for (i in tabLines) {                         
                    tabLines[i].setPath(new Array());
                }  
                for (i in directionsR){
                    directionsR[i].setMap(null);
                }
                currentNote = 0;
                tabMarqueurs = new Array();
                contentInfo = new Array();
                tabLines = new Array();
                directionsR = new Array();
                initParticular(id);
                document.getElementById("parcours").style.visibility = "visible";
            }
            
            function initParticular(id){
                $.ajax({
                    async: "false",
                    url: "/GeoNotesClient/servlet/getParcours",
                    data: {particular: id},
                    success: function(data){
                        var parcours = JSON.parse(data);
                        for(i = 0; i< parcours.length;i++){
                            color = get_random_color();
                            latlong = new Array();       
                            for(j = 0; j<parcours[i].notes.length; j++){
                                initNote(parcours[i].notes[j].titre, parcours[i].notes[j].longitude, parcours[i].notes[j].latitude, parcours[i].notes[j].altitude, parcours[i].notes[j].id, true);
                                latlong.push(new google.maps.LatLng(parcours[i].notes[j].latitude,parcours[i].notes[j].longitude));
                            }  
                            if(latlong.length <= 10){
                                var begin = latlong[0];
                                var end = latlong[latlong.length-1];
                                var waypoints = new Array();
                                for(j=1; j<latlong.length-1;j++){
                                    waypoints.push(latlong[j]);
                                }
                                directionsServiceM(begin,end,waypoints, color);
                            }
                            else{
                                isOk = false;
                                index = 0;                                
                                while(!isOk){
                                    var waypoints = new Array();
                                    begin = latlong[index];
                                    if(latlong[index+9] != undefined){
                                        end = latlong[index+9];
                                        for(j=index+1; j<index+9;j++){
                                            waypoints.push(latlong[j]);
                                        }                                        
                                        directionsServiceM(begin,end,waypoints, color);
                                        index+=10;
                                    }
                                    else{
                                        end = latlong[latlong.length-1];
                                        for(j=index+1; j<latlong.length;j++){
                                            waypoints.push(latlong[j]);
                                        }
                                        directionsServiceM(begin,end,waypoints, color);
                                        isOk = true;
                                    }
                                }
                            }
                            nodeParcours = document.getElementById("parcours");
                            pContainer = document.createElement("p");
                            pContainer.innerHTML = "<h3>"+parcours[i].titre+"</h3><br/>";
                            pContainer.innerHTML += "<b>Créateur</b> : "+parcours[i].owner+"<br/>";
                            nodeParcours.appendChild(pContainer);
                        }
                    }
                });
            }
            
            function reinitAll(){
                for (i in tabMarqueurs) {     
                    tabMarqueurs[i].setMap(null);    
                }  
                for (i in tabLines) {     
                    tabLines[i].setMap(null);    
                }  
                for (i in directionsR){
                    directionsR[i].setMap(null);
                }
                tabMarqueurs = new Array();
                contentInfo = new Array();                
                tabLines = new Array();
                directionsR = new Array();
                currentNote = 0;
                initAllParcours();
                nodeParcours = document.getElementById("parcours");
                while(nodeParcours.hasChildNodes()){
                    nodeParcours.removeChild(nodeParcours.firstChild);
                }
                nodeParcours.style.visibility = "hidden";
            }
                
            function reinitMine(){
                for (i in tabMarqueurs) {     
                    tabMarqueurs[i].setMap(null);    
                }  
                for (i in tabLines) {     
                    tabLines[i].setMap(null);    
                }  
                for (i in directionsR){
                    directionsR[i].setMap(null);
                }
                currentNote = 0;
                tabMarqueurs = new Array();
                contentInfo = new Array();
                tabLines = new Array();
                directionsR = new Array();
                initMesParcours();
                nodeParcours = document.getElementById("parcours");
                while(nodeParcours.hasChildNodes()){
                    nodeParcours.removeChild(nodeParcours.firstChild);
                }
                nodeParcours.style.visibility = "hidden";
            }
            
            function initAllParcours(){
                $.ajax({
                    async: "false",
                    url: "/GeoNotesClient/servlet/getParcours",
                    data: {mine:"false"},
                    success: function(data){
                        var parcours = JSON.parse(data);
                        for(i = 0; i< parcours.length;i++){
                            latlong = new Array();       
                            for(j = 0; j<parcours[i].notes.length; j++){
                                initNote(parcours[i].notes[j].titre, parcours[i].notes[j].longitude, parcours[i].notes[j].latitude, parcours[i].notes[j].altitude, parcours[i].notes[j].id, true);
                                latlong.push(new google.maps.LatLng(parcours[i].notes[j].latitude,parcours[i].notes[j].longitude));
                            }       
                            parcoursLine = new google.maps.Polyline(
                            {   
                                map:map,
                                path:latlong,
                                strokeColor:get_random_color(),
                                strokeOpacity:0.8,
                                strokeWeight:2
                            });
                            google.maps.event.addListener(parcoursLine, 'click', (function(parcoursLine,i){
                                return function(){
                                    reinitParticular(parcours[i].id);
                                }
                            })(parcoursLine,i));                            
                            tabLines.push(parcoursLine);                            
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
                currentNote++;
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
               
            function get_random_color() {
                var letters = '0123456789ABCDEF'.split('');
                var color = '#';
                for (var i = 0; i < 6; i++ ) {
                    color += letters[Math.round(Math.random() * 15)];
                }
                return color;
            }
           

        </script>
    </head>
    <body onload="initialise()">        
        <div id="map_canvas"></div>
        <div id="titre" class ="lightbox"><h2>Voir Parcours</h2></div>
        <div id="info" class="lightbox"><br/>
            <table>
                <tr>
                    <td><a href="/GeoNotesClient/geonotes.jsp">Créer une note </a></td>
                </tr><tr>
                    <td><a href="/GeoNotesClient/updateNote.jsp"> Modifier une note </a></td>
                </tr><tr>
                    <td><a href="/GeoNotesClient/createParcours.jsp"> Créer un parcours </a></td>
                </tr><tr>
                    <td><a href="#" onclick="reinitMine()"> Voir mes parcours </a></td>                    
                </tr><tr>
                    <td><a href="#" onclick="reinitAll()"> Voir tous les parcours </a></td>
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
        <div id="parcours" class="lightBox"></div>
        <div id="legende" class="lightBox">
            <h5>Parcours</h5>
            <ul>
                <li>clic gauche : afficher les informations</li>
                <li>clic droit : supprimer ( seulement en vue: "mes parcours" )</li>
            </ul>
            <br/>
            <h5>Note</h5>
            <ul>
                <li>clic gauche : afficher les informations</li>
            </ul>
        </div>
    </body>
</html>
