/**
 * The Ecstasy standard module for basic networking support.
 */
module net.xtclang.org
    {
    package crypto import crypto.xtclang.org;

    /**
     *
     */
    typedef Tuple<String|IPAddress, UInt16> as HostPort;

    /**
     *
     */
    typedef Tuple<IPAddress, UInt16> as SocketAddress;
    }