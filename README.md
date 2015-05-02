# Dummy API

Dummy API is an API which behaviour is decided by the request headers and
query parameters. The purpose is to use it for testing and benchmarking API
gateways such as the Varnish API Engine.

## Headers and query parameters

The following request headers and query parameters will make an impact on the response.

### Delay

    header-delay = {float}           Delay to first header byte
    body-delay = {float}             Delay to first body byte

### Cache-control

    max-age = {int}                  Set the response max-age value
    s-maxage = {int}                 Set the response s-maxage value
    must-revalidate                  Set must-revalidate
    public                           Set public
    private                          Set private
    no-store                         Set no-store
    no-cache                         Set no-cache
    no-transform                     Set no-transform

### Misc

    content-length                   Set the content-length header, otherwise chunked transfer encoding is used
    random-content = {int}           Add random string to the response of given length
    predictable-content = {int}      Add predictable string to the response of given length
    response-status = {int}          Set the response status
    help                             Show help text

## Examples

    GET http://somehost/someurl?max-age=2&content-length&header-delay=1
    
    HTTP/1.1 200 OK
    Cache-control: max-age=2
    Connection: close
    Content-Type: application/json
    Content-length: 106
    Date: Fri, 01 May 2015 19:25:11 GMT
    Server: Dummy API
    
    {
        "content-length": true,
        "header-delay": 1,
        "host": "somehost",
        "max-age": 2,
        "method": "GET",
        "uri": "/someurl"
    }

## Getting help

    GET http://somehost/?help

## Installation

    wget http://openresty.org/download/ngx_openresty-1.7.10.1.tar.gz
    tar -xvzf ngx_openresty-1.7.10.1.tar.gz
    cd ngx_openresty-1.7.10.1
    ./configure --with-pcre-jit --with-luajit --error-log-path=/var/log/dummy-api/error.log --http-log-path=/var/log/dummy-api/access.log --prefix=/srv/dummy-api/openresty/
    gmake
    gmake install 
    mkdir -p /srv/dummy-api/conf
    cp etc/dummy-api.init /etc/init.d/dummy-api
    cp etc/nginx.conf /srv/dummy-api/conf/
    service dummy-api start

