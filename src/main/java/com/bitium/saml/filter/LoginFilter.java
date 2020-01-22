package com.bitium.saml.filter;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.atlassian.sal.api.auth.LoginUriProvider;
import com.bitium.saml.config.SAMLConfig;

public class LoginFilter implements Filter {

    private SAMLConfig config;
    private LoginUriProvider loginUriProvider;

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {
        //boolean idpRequired = config.getIdpRequiredFlag();
        boolean idpRequired = false;
        HttpServletRequest req = (HttpServletRequest)request;
        HttpServletResponse res = (HttpServletResponse)response;

        if (idpRequired == true) {
            try {
                res.sendRedirect(loginUriProvider.getLoginUri((new URI(req.getRequestURI().toString()))).toString() + "&samlerror=general");
            } catch (URISyntaxException e) {
            }
        } else {
            chain.doFilter(request, response);
        }
    }

    @Override
    public void destroy() {
    }

    public void setConfig(SAMLConfig config) {
        this.config = config;
    }

    public void setLoginUriProvider(LoginUriProvider loginUriProvider) {
        this.loginUriProvider = loginUriProvider;
    }

}
