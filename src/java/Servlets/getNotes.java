/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package Servlets;

import GeoNotesEJB.GeoNotesRemote;
import NoteEJB.Note;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.JSONValue;

/**
 *
 * @author Jacky
 */
public class getNotes extends HttpServlet {

    /**
     * Processes requests for both HTTP
     * <code>GET</code> and
     * <code>POST</code> methods.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        PrintWriter out = response.getWriter();
        GeoNotesRemote bean = (GeoNotesRemote) request.getSession().getAttribute("bean");
        if (bean == null) {
            try {
                InitialContext ctx = new InitialContext();
                bean = (GeoNotesRemote) ctx.lookup("GeoNote");
                request.getSession().setAttribute("bean", bean);
            } catch (NamingException ex) {
                Logger.getLogger(getNotes.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
        boolean isMine = Boolean.parseBoolean(request.getParameter("mine"));
        List<Note> col;
        if (isMine) {
            col = bean.findMyNotes();
        } else {
            col = bean.findAllNotes();
        }
        JSONArray list = new JSONArray();
        for (Note n : col) {
            JSONObject json = new JSONObject();
            json.put("id", n.getId());
            json.put("altitude", n.getAltitude());
            json.put("titre", n.getDescription());
            json.put("longitude", n.getLongitude());
            json.put("latitude", n.getLatitude());
            list.add(json);
        }
        out.print(JSONValue.toJSONString(list));
    }

    // <editor-fold defaultstate="collapsed" desc="HttpServlet methods. Click on the + sign on the left to edit the code.">
    /**
     * Handles the HTTP
     * <code>GET</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Handles the HTTP
     * <code>POST</code> method.
     *
     * @param request servlet request
     * @param response servlet response
     * @throws ServletException if a servlet-specific error occurs
     * @throws IOException if an I/O error occurs
     */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>
}
