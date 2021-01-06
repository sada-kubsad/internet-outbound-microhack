// This PAC file will provide proxy config to Microsoft 365 services
//  using data from the public web service for all endpoints
function FindProxyForURL(url, host)
{
    var direct = "DIRECT";
    var proxyServer = "PROXY 10.57.2.4:3127";

    if(shExpMatch(host, "ipinfo.io"))
    {
        return direct;
    }

    return proxyServer;
}
