import collections.IdentitySet;

import net.IPAddress;

import web.CookieConsent;
import web.Header;
import web.TrustLevel;

import web.codecs.Base64Format;

import HttpServer.RequestInfo;

import TimeOfDay.PICOS_PER_SECOND;


/**
 * A representation of a session cookie. There are three session cookies used:
 *
 * 1. `xplaintext` - a non-persistent cookie that is subject to hijacking (not protected by TLS)
 *    * this cookie is created when any request arrives without a `xplaintext` cookie
 *    * specifies `Path=/;SameSite=Strict;HttpOnly`; does not specify `Expires` or `Domain`
 *    * contains base64 encoding of encrypted data: session id, cookie id, change counter, creation
 *      date, known consents, known cookies (1/2/3), ip address, random salt
 *
 * 2. `__Host-xtemporary` - a non-persistent cookie protected by TLS
 *    * this cookie is created when a request comes in over a TLS connection and there is no
 *      `__Host-xtemporary` cookie in the request
 *    * specifies `Path=/;SameSite=Strict;secure;HttpOnly`; does not specify `Expires` or `Domain`
 *    * contains base64 encoding of encrypted data: session id, cookie id, change counter, creation
 *      date, known consents, known cookies (1/2/3), ip address, random salt
 *
 * 3. `__Host-xconsented` - a persistent cookie protected by TLS
 *    * this cookie is only created when a request comes in over a TLS connection, and the session
 *      [cookieConsent] has been set, and there is no `__Host-xconsented` cookie in the request
 *    * specifies `Path=/;SameSite=Strict;secure;HttpOnly;Expires=...` ; does not specify `Domain`
 *    * contains human readable consent string and date/time of consent
 *    * contains base64 encoding of encrypted data: session id, cookie id, change counter, creation
 *      date, expiry, known consents, known cookies (1/2/3), ip address, random salt
 *    * if consent is withheld, then the session id and IP address are **not** recorded in the
 *      persistent portion.
 *
 * Notes:
 *
 * * All three cookies may show up on a secure connection, but it's always possible that any
 *   combination of the cookies can show up with any request. Here is how the server handles an
 *   incoming request with some combination of cookies 1, 2, and 3, with (1) or without (0) TLS:
 *
 *     1 2 3 TLS  description/action
 *     - - - ---  ------------------
 *            0   create new session; create cookie 1; redirect to verification
 *            1   create new session; create cookies 1 and 2; redirect to verification
 *     x      0   validate cookie 1
 *     x      1   validate cookie 1 & verify [prevTLS_] `== False`; create cookie 2;
 *                redirect to verification; set [prevTLS_] `= True`
 *       x    0   error (no TLS, so cookie 2 is illegally present; also missing cookie 1)
 *       x    1   error (missing cookie 1)
 *     x x    0   error (no TLS, so cookie 2 is illegally present)
 *     x x    1   validate cookie 1 & 2; if [cookieConsent] has been set, create cookie 3 and
 *                redirect to verification
 *         x  0   error (no TLS, so cookie 3 is illegally present)
 *         x  1   validate cookie 3; assume temporary cookies absent due to user agent restart;
 *                create cookie 1 & 2 and redirect to verification
 *     x   x  0   error (no TLS, so cookie 3 is illegally present)
 *     x   x  1   validate cookie 1 & 3 (1 must be newer than 3), and verify [prevTLS_] `== False`;
 *                use session specified by cookie 3 if possible, otherwise 1; create cookie 2;
 *                redirect to verification; set [prevTLS_] `= True`
 *       x x  0   error (no TLS, so cookie 2 and 3 are illegally present)
 *       x x  1   error (missing cookie 1)
 *     x x x  0   error (no TLS, so cookies 2 and 3 are illegally present)
 *     x x x  1   validate cookie 1 & 2 & 3 (must be identical)
 *
 * * When a cookie is created, the counter inside the cookie is incremented, and any existing
 *   cookies are also re-written so their contents are in agreement (although each necessarily
 *   differing at a binary level, in order to make spoofing of one cookie from another cookie's
 *   contents impossible)
 *
 * * Cookies need to be replaced whenever an IP address etc. changes, also after a period of time.
 *
 * * Persistent cookies are only used when permission has been given to use persistent cookies.
 *
 * * When a session is first created on a plaintext connection, it uses a temporary cookie and no
 *   significant information is expected to be related to that session (because of the lack of TLS).
 *   Subsequently, when transitioning to a TLS connection, a previously existent persistent
 *   connection may suddenly show up with the first request over TLS, and for which session data
 *   (perhaps even persistent session data) may exist. In that case, the session indicated by the
 *   persistent (and TLS) session ID is used, possibly with a few details lifted from the non-TLS
 *   session before it is discarded, and all three cookies are then re-written.
 */
const SessionCookie
        implements Destringable
    {
    // ----- constructors --------------------------------------------------------------------------

    @Override
    construct(String text)
        {
        // if the text is the entire toString() value, then just extract the cookie value from it
        if (Int assign := text.indexOf('='))
            {
            // cache the full cookie text from the toString()
            this.text = text;

            assert Int semi := text.indexOf(';');
            text = text[assign >..< semi];
            }

        // check if this is the consent cookie (it will have some plain text up front)
        String? plain = Null;
        if (Int div := text.lastIndexOf('/'))
            {
            plain = text[0 ..< div];
            text  = text.substring(div+1);
            }

        // decrypt and deserialize the cookie value
        text = decrypt(text);
        String[] parts = text.split(',');
        this.sessionId    = new Int(parts[0]);
        this.cookieId     = CookieId.values[new Int(parts[1])];
        this.knownCookies = new Int(parts[2]);
        this.consent      = new CookieConsent(parts[3]);
        this.expires      = parts[4] == "" ? Null : roundTime(new Time(new Int128(parts[4]) * PICOS_PER_SECOND));
        this.lastIp       = new IPAddress(parts[5]);
        this.created      = roundTime(new Time(new Int128(parts[6]) * PICOS_PER_SECOND));
        this.version      = new Int(parts[7]);
        this.salt         = new UInt16(parts[8]);

        // make sure that the plain text wasn't tampered with
        if (plain != Null)
            {
            assert cookieId == Consent && knownCookies == CookieId.All;
            CookieConsent checkConsent = new CookieConsent(plain);
            assert consent == checkConsent;
            }
        }

    /**
     * Construct a SessionCookie from its constituent members.
     *
     * @param sessionId     the session identity
     * @param cookieId      the cookie identity used by the user agent
     * @param knownCookies  the bitset of known cookies for the user agent
     * @param consent       the known cookie consent
     * @param expires       the point in time at which the cookie is set to automatically expire
     * @param lastIp        the last known IP address of the user agent
     * @param created       (optional) the time when the cookie was originally created
     * @param version       (optional) the current version of the cookie
     * @param salt          (optional) the salt value to include when encrypting the cookie
     * @param text          (optional) the text of the cookie, as provided by the user agent
     */
    construct(Int           sessionId,
              CookieId      cookieId,
              Int           knownCookies,
              CookieConsent consent,
              Time?         expires,
              IPAddress     lastIp,
              Time?         created = Null,
              Int?          version = Null,
              UInt16?       salt    = Null,
              String?       text    = Null,
             )
        {
        this.sessionId    = sessionId;
        this.cookieId     = cookieId;
        this.knownCookies = knownCookies;
        this.consent      = consent;
        this.expires      = expires;
        this.lastIp       = lastIp;
        this.created      = roundTime(created ?: clock.now);
        this.version      = version ?: 1;
        this.salt         = salt == Null || salt == 0 ? makeSalt() : salt;
        this.text        ?= text;
        }

    /**
     * Construct a copy of this SessionCookie with the specified changes.
     *
     * @param sessionId     (optional) the session identity
     * @param cookieId      (optional) the cookie identity used by the user agent
     * @param knownCookies  (optional) the bitset of known cookies for the user agent
     * @param consent       (optional) the known cookie consent
     * @param expires       (optional) the point in time at which the cookie should expire
     * @param lastIp        (optional) the last known IP address of the user agent
     * @param created       (optional) the time when the cookie was originally created
     * @param version       (optional) the current version of the cookie
     * @param salt          (optional) the salt value to include when encrypting the cookie
     * @param text          (optional) the text of the cookie, as provided by the user agent
     *
     * @return the new SessionCookie containing the specified changes
     */
    SessionCookie with(Int?           sessionId    = Null,
                       CookieId?      cookieId     = Null,
                       Int?           knownCookies = Null,
                       CookieConsent? consent      = Null,
                       Time?          expires      = Null,
                       IPAddress?     lastIp       = Null,
                       Time?          created      = Null,
                       Int?           version      = Null,
                       UInt16?        salt         = Null,
                       String?        text         = Null,
                      )
        {
        return new SessionCookie(sessionId    = sessionId    ?: this.sessionId,
                                 cookieId     = cookieId     ?: this.cookieId,
                                 knownCookies = knownCookies ?: this.knownCookies,
                                 consent      = consent      ?: this.consent,
                                 expires      = expires      ?: this.expires,
                                 lastIp       = lastIp       ?: this.lastIp,
                                 created      = created      ?: this.created,
                                 version      = version      ?: this.version + 1,
                                 salt         = salt         ?: makeSalt(this.salt),
                                 text         = text,
                                );
        }


    // ----- properties ----------------------------------------------------------------------------

    /**
     * CookieId identifies which of the three possible cookies a session cookie is.
     */
    enum CookieId(String name, Boolean tlsOnly, Boolean persistent, String attributes)
        {
        PlainText(       "xplaintext", False, False, "; Path=/; SameSite=Strict; HttpOnly"),
        Encrypted("__Host-xtemporary", True , False, "; Path=/; SameSite=Strict; HttpOnly; Secure"),
        Consent  ("__Host-xconsented", True , True , "; Path=/; SameSite=Strict; HttpOnly; Secure");

        /**
         * A bitset representing no cookies.
         */
        static Int None  = 0x0;

        /**
         * A bitset representing just the plaintext cookie.
         */
        static Int NoTls = 0x1;

        /**
         * A bitset representing all three cookies.
         */
        static Int All   = 0x7;
        }


    // ----- properties ----------------------------------------------------------------------------

    /**
     * The temporally unique session identifier.
     */
    Int sessionId;

    /**
     * The identity of the cookie, as seen by the user agent.
     */
    CookieId cookieId;

    /**
     * The set of cookies on the user agent that were sent from and/or being provided by the user
     * agent at the time when this version of this cookie was created.
     */
    Int knownCookies;

    /**
     * The known CookieConsent at the time when this version of this cookie was created.
     */
    CookieConsent consent;

    /**
     * The point in time at which this cookie is known to expire. Cookies can be expired at any time
     * by the user agent, or may disappear for other reasons; cookies can also be retained by a user
     * agent beyond their suggested expiry. Regardless, the user agent does not send the expiry time
     * with the cookie, so the information is redundantly recorded inside the cookie.
     */
    Time? expires;

    /**
     * The IP address of the user agent that was recorded when this version of this cookie was
     * created.
     */
    IPAddress lastIp;

    /**
     * The time that the oldest known version of this cookie was created.
     */
    Time created;

    /**
     * The version counter for this cookie. Each change to the cookie increments the version
     * counter.
     */
    Int version;

    /**
     * Random salt; never zero.
     */
    UInt16 salt;

    /**
     * The text of the cookie, as passed in by the user agent, or as rendered from the provided
     * information.
     */
    @Lazy String text.calc()
        {
        // render the portion to encrypt that contains the session ID etc.
        StringBuffer buf = new StringBuffer();

        cookieId.name.appendTo(buf)
            .add('=');

        if (cookieId.persistent)
            {
            consent.appendTo(buf)
                   .add('/');
            }

        String raw = $|{sessionId},{cookieId.ordinal},{knownCookies},{consent},\
                      |{encodeTime(expires)},{lastIp},{encodeTime(created)},{version},{salt}
                     ;
        encrypt(raw).appendTo(buf);

        cookieId.attributes.appendTo(buf);

        return buf.toString();
        }


    // ----- encoding support ----------------------------------------------------------------------

    /**
     * Encrypt the passed readable string into an unreadable, tamper-proof, BASE-64 string
     *
     * @param text  the readable string
     *
     * @return the encrypted string in BASE-64 format
     */
    static String encrypt(String text)
        {
        Byte[] bytes = text.utf8();
        // TODO CP bytes = encryption ...
        return Base64Format.Instance.encode(bytes);
        }

    /**
     * Decrypt the passed string back into a readable String
     *
     * @param text  the encrypted string in BASE-64 format
     *
     * @return the readable string
     */
    static String decrypt(String text)
        {
        try
            {
            Byte[] bytes = Base64Format.Instance.decode(text);
            // TODO CP bytes = decryption ...
            return bytes.unpackUtf8();
            }
        catch (Exception e)
            {
            return "";
            }
        }

    /**
     * Round the time to the nearest second.
     *
     * @param time  a time value
     *
     * @return the UTC time value rounded to the nearest second
     */
    static Time roundTime(Time time)
        {
        return time.timezone == UTC && time.epochPicos % PICOS_PER_SECOND == 0
                ? time
                : new Time(time.epochPicos / PICOS_PER_SECOND * PICOS_PER_SECOND);
        }

    /**
     * Produce a string that represents the passed time value.
     *
     * @param time  a time value
     *
     * @return a compact string representation of the time value
     */
    static String encodeTime(Time? time)
        {
        return (time?.epochPicos/PICOS_PER_SECOND).toString() : "";
        }

    /**
     * Parse a string returned from [encodeTime] into a time value.
     *
     * @param seconds  a compact string representation of a time value
     *
     * @return  the time value
     */
    static Time? decodeTime(String seconds)
        {
        if (seconds == "" || seconds == "0")
            {
            return Null;
            }

        try
            {
            return new Time(new Int128(seconds) * PICOS_PER_SECOND);
            }
        catch (Exception e)
            {
            return Null;
            }
        }


    // ----- internal helpers ----------------------------------------------------------------------

    /**
     * Create a new salt value.
     *
     * @param oldSalt  the old salt value
     *
     * @return the new salt value, never equal to either zero or the previous salt value
     */
    static UInt16 makeSalt(UInt16 oldSalt = 0)
        {
        UInt16 salt;
        do
            {
            // TODO GG:  salt = rnd.uint(0xFFFF).toUInt16();
            salt = xenia.rnd.uint(0xFFFF).toUInt16();
            }
        while (salt == 0 || salt == oldSalt);
        return salt;
        }


    // ----- Stringable methods --------------------------------------------------------------------

    @Override
    Int estimateStringLength()
        {
        return text.size;
        }

    @Override
    Appender<Char> appendTo(Appender<Char> buf)
        {
        return text.appendTo(buf);
        }
    }