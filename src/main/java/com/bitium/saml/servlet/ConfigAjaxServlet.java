package com.bitium.saml.servlet;

import com.bitium.saml.config.SAMLConfig;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import com.atlassian.sal.api.pluginsettings.PluginSettings;
import com.atlassian.sal.api.pluginsettings.PluginSettingsFactory;

/**
 * For now it does only one function: returns idpRequired Field
 *
 * This might probably get expanded to return json with other fields as well
 *
 */
public class ConfigAjaxServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

/*
    private SAMLConfig saml2Config;

    public void setSaml2Config(SAMLConfig saml2Config) {
        this.saml2Config = saml2Config;
    }
*/

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String parameter = request.getParameter("param");
        if (parameter != null) {
            if (parameter.equals("idpRequired")) {
                //response.getOutputStream().write(saml2Config.getIdpRequired().getBytes());
		response.getOutputStream().write("false".getBytes());
            } else if (parameter.equals("logoutUrl")) {
                //response.getOutputStream().write(saml2Config.getLogoutUrl().getBytes());
		response.getOutputStream().write("https://".getBytes());
            }
        }
    }
}
