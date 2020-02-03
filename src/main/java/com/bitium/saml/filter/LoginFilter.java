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
import com.atlassian.sal.api.pluginsettings.PluginSettings;
import com.atlassian.sal.api.pluginsettings.PluginSettingsFactory;
//import org.apache.commons.logging.Log;
//import org.apache.commons.logging.LogFactory;
import org.slf4j.LoggerFactory;
import org.slf4j.Logger;

import org.apache.commons.lang.StringUtils;

import com.atlassian.sal.api.auth.LoginUriProvider;
import com.bitium.saml.config.SAMLConfig;

public class LoginFilter implements Filter {

    private SAMLConfig config;
    private LoginUriProvider loginUriProvider;
    //private static final Log log = LogFactory.getLog(LoginFilter.class);
    private static final Logger logger = LoggerFactory.getLogger((Class)LoginFilter.class);

    public LoginFilter(PluginSettingsFactory pluginSettingsFactory, LoginUriProvider luri) {
	    config = new SAMLConfig();
            config.setPluginSettingsFactory(pluginSettingsFactory);
            loginUriProvider = luri;
        }

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {
        boolean idpRequired = config.getIdpRequiredFlag();
        boolean allowOverride = config.getAllowOverrideFlag();
        String  overridePin = StringUtils.defaultString(config.getOverridePin());
        String  overrideStr = "?uselocallogin"+overridePin;

        HttpServletRequest req = (HttpServletRequest)request;
        HttpServletResponse res = (HttpServletResponse)response;

        if (idpRequired) {
            try {
		String referrer = StringUtils.defaultString((String)req.getHeader("referer"),"");  
                String rhost = StringUtils.defaultString((String)req.getRemoteHost(),"");
                String raddr = StringUtils.defaultString((String)req.getRemoteAddr(),"");
		if (StringUtils.endsWith(referrer,overrideStr) & allowOverride & !StringUtils.isEmpty(overridePin)) {
                  //log.error("SAML Backdoor used: " + rhost + " " + raddr + " " + referrer);
                  LoginFilter.logger.error("SAML Backdoor used: " + rhost + " " + raddr + " " + referrer);
                  chain.doFilter(request, response);
                  } else {
                 res.sendRedirect(loginUriProvider.getLoginUri((new URI(req.getRequestURI().toString()))).toString() + "&samlerror=general");
                 }
            } catch (URISyntaxException e) {
            }
        } else {
            chain.doFilter(request, response);
        }
    }

    @Override
    public void destroy() {
    }

    //public void setConfig(SAMLConfig config) {
    //    this.config = config;
    //}

    //public void setLoginUriProvider(LoginUriProvider loginUriProvider) {
    //    this.loginUriProvider = loginUriProvider;
    //}

}
