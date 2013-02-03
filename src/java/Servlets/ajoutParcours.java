/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package Servlets;

import GeoNotesEJB.GeoNotesRemote;
import NoteEJB.Note;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Enumeration;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.json.simple.ItemList;
import org.json.simple.JSONArray;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

/**
 *
 * @author Jacky
 */
public class ajoutParcours extends HttpServlet {

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
        GeoNotesRemote bean = (GeoNotesRemote) request.getSession().getAttribute("bean");
        try {
            if (bean == null) {
                InitialContext ctx = new InitialContext();
                bean = (GeoNotesRemote) ctx.lookup("GeoNote");
                request.getSession().setAttribute("bean", bean);
            }
            JSONArray json = (JSONArray) new JSONParser().parse(request.getParameter("tableau"));
            Note[] ntab = new Note[Integer.parseInt(request.getParameter("tablength"))];
            int i = 0;
            for (Object o : json) {
                System.err.println(o.toString());
                ntab[i] = bean.getNote(Long.parseLong(o.toString()));
                i++;
            }
            bean.setParcours(ntab, request.getParameter("title"));
            getServletContext().getRequestDispatcher("/mesparcours.jsp").forward(request, response);

        } catch (NamingException ex) {
            Logger.getLogger(ajoutParcours.class.getName()).log(Level.SEVERE, null, ex);
        } catch (ParseException ex) {
            Logger.getLogger(ajoutParcours.class.getName()).log(Level.SEVERE, null, ex);
        }
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
