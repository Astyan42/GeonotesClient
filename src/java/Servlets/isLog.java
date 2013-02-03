/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package Servlets;

import GeoNotesEJB.GeoNotesRemote;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 *
 * @author Jacky
 */
@WebServlet(name = "isLog", urlPatterns = {"/isLog"})
public class isLog extends HttpServlet {

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
        try {
            GeoNotesRemote bean = (GeoNotesRemote) request.getSession().getAttribute("bean");
            if (bean == null) {
                InitialContext ctx = new InitialContext();
                bean = (GeoNotesRemote) ctx.lookup("GeoNote");
                request.getSession().setAttribute("bean", bean);
            }
            if (!bean.isLogged()) {
                request.setAttribute("isLogged", false);
                request.getSession().setAttribute("bean", null);
                getServletContext().getRequestDispatcher("/index.jsp")
                        .forward(request, response);
            } else {
                getServletContext().getRequestDispatcher("/geonotes.jsp").forward(request, response);
            }
        } catch (NamingException ex) {
            Logger.getLogger(isLog.class.getName()).log(Level.SEVERE, null, ex);
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
