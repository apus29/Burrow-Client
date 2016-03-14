# Project Plan

## Motivation

Though the world wide web is meant to be accessible to everyone, this is sometimes not the case when using certain networks that restrict access to the internet. Examples of these restrictions include paywalled WiFi, blocked websites on school networks, and censorship of some or all sites in countries ruled by oppressive governments. Bypassing these obstacles is commonly achieved by tunneling network traffic around the filtering mechanism to another device that has unrestricted Internet access. This only works when the filter or obstacle does not realize that traffic is being routed around it. SSH forwarding and VPNs are common examples of such workarounds, but can be detected and due to their popularity are often blocked. DNS tunneling is an unusual and hard-to-detect method of bypassing network barriers by routing all network traffic through the DNS system.

Common tools for circumventing China’s Great Firewall (GFW) are proxies, VPNs, and SSH tunneling. Proxies are an unreliable option since they are usually identified and blocked fairly quickly. VPNs use dedicated ports that the government can block completely without disrupting other traffic, and VPN communication with foreign IP addresses can be detected and blocked relatively easily. SSH tunneling used to be a reliable way to bypass the firewall, but the government has been recently cracking down on it. SSH tunneling is encrypted in such a way that the GFW usually cannot determine with certainty if it is tunneling illegal traffic. As a result, the government has recently been preemptively tampering with SSH tunnels that they believe might be performing illegal operations. Thus, the game of cat and mouse continues, and new ways of bypassing these firewalls are necessary.

DNS traffic is a promising alternative to traditional tunneling channels. Tunneling over the DNS protocol is difficult to detect and filter, and information transferred across this protocol is crucial to the functionality of the Internet. Tampering with DNS traffic can have major side-effects, and relatively long cache times can result in problems caused by tampered data persisting for long periods of time. Perhaps more importantly, DNS tunneling is currently not commonly used as a way of bypassing Internet filters. As a result, attempting to detect and block DNS traffic that may be bypassing the filter is usually not worth the risk of potentially breaking the average user’s Internet for several hours. Thus, using DNS to tunnel traffic is a promising technique for bypassing Internet filters.

There are a number of DNS tunneling programs available, but most are designed for use on desktop/laptop computers and require significant technical skill and effort to configure. The number of mobile Internet users has been increasing at a breakneck pace since 2007, and in 2014 even exceeded the number of desktop Internet users [10]. The vast majority of Internet users aren’t skilled or motivated enough to set up their own server, and don’t have easy access to the resources to do so - particularly if they live under an oppressive government. Our goal is to create a turnkey iOS app that allows a non-technical user to browse the web through a DNS tunnel, including providing our own managed cloud server to relay data.

## Technical Details
#### Intercepting Client-Side Network Traffic

Depending on whether we receive permission to build a network extension from Apple (more about that later), we will build either an in-app web browser or a system-wide network extension to DNS tunnel traffic. We’ll first describe the conservative scenario in which we do not receive the entitlement and must build the in-app web browser, then we’ll describe the preferable scenario in which we build the network extension.

The app would provide a web browser interface backed by a DNS tunnel to our server. We wouldn’t have to build the web browsing logic ourselves though. We would be utilizing the class UIWebView, part of the UIKit framework on iOS, to provide the web browsing UI and logic. In iOS 8, WKWebView was introduced as a replacement for UIWebView (although UIWebView was not deprecated), but the newer package is actually less useful for our purposes. For performance and security reasons, WKWebView handles web requests in a separate process, but this means we would not be able to intercept and fulfill these requests ourselves due to iOS’s strict sandboxing restrictions.

The Foundation framework on iOS includes many useful classes for “interacting with URLs and communicating with severs using standard Internet protocols” [3]. Specifically, Foundation’s URL loading system provides a protocol called NSURLProtocol that allows for the implementation of an object that performs custom loading behavior in response to URL requests made in the web view [4]. We can intercept the request (including HTTP headers, etc.) and instead perform it through DNS. At launch, an app may register custom protocol classes with Foundation such that subsequent URL requests may be handled by our custom networking logic. This would allow us to handle most sorts of web traffic through our DNS tunnel, even AJAX. Note that intercepting requests through NSURLProtocol is a bit leaky in that certain traffic, such as videos which iOS plays through an embedded version of the system video player, will not pass through our tunnel.

This limitation is avoided by building a network tunnel extension so all traffic across the system passes through the DNS tunnel. iOS 9 in 2015 introduced an series of extension points, most relevantly NETunnelProvider [7]. This extension point is exactly what we’d need to provide system-wide support so that the user can tunnel their traffic in any app. An app that provides such an extension must include in its code signature a special entitlement from Apple; otherwise, the operating system will prevent the app from using the tunneling extension point. Unfortunately, unlike most iOS public APIs, the entitlement required to use this extension point is not made available to any developer that requests it. Apple provides a special form for developers to request the entitlement [8]. For this reason, we’ll plan to use the approach utilizing a in-app web browser until we hear back from Apple (since this would not require the extension).

If we are granted access to the entitlement, we’ll opt to forgo the in-app web browser and opt to instead build the system-wide tunneling extension. An interesting distinction between the UIWebView approach and the NETunnelProvider approach is that the former operates on the transport layer while the latter operates on the network layer. This means that a NETunnelProvider extension should be able to handle TCP traffic as well as UDP traffic, while the UIWebView approach would only target TCP traffic. Note that the UIWebView approach does not require us to reimplement TCP since DNS works over TCP, so we’d effectively just be operating between the transport and the application layer.

#### Performing DNS Requests on the Client

We will outline the approach we will take to implement DNS tunneling for the in-app web browser approach. If we take the network extension approach, slight modifications will be needed, but it’ll be simpler overall. Our plan is to develop custom code on the client which will intercept HTTP requests, download the HTTP response for that request from our server (which will have fetched it from the Internet) through the DNS protocol, and then return the downloaded HTTP response.

The sequence of events on the client will be roughly as follows:

1. HTTP request is intercepted
2. Request is encoded in base64 (encodedrequest)
3. Call the normal system DNS resolver on each encodedrequestblock.ourdomain.com
4. Receive response, which will be a session token and number of chunks *n*
5. For *index* in range(0, *n*), call the normal system DNS resolver on index.token.ourdomain.com and write each successive received data packet of the response to disk
6. Finally, respond to the original intercepted request with the saved response

In the event that we can’t successfully implement this process ourselves, we plan to attempt to integrate an existing open-source DNS tunneling library.

#### Fulfilling DNS Requests on the Server

An important component of our project is the cloud service that actually accesses the Internet on behalf of our client devices. At first this will probably be an always-on Linux-based VM on a local computer, but if we decide to attempt to grow the service we will investigate moving it to a professional hosting provider.

Our server will receive DNS requests of the format encodedrequest.ourdomain.com, triggering the following sequence of events.


1. hostname is decoded as base64 data and verified to be a valid HTTP request
2. The HTTP request is fulfilled with a standard system library and the HTTP response is saved
3. A session token is randomly generated and the number of DNS responses required to return the entire HTTP response is calculated, then returned to the client in the body of the HTTP response.

Our server will also get DNS requests of the format index.token.ourdomain.com, which will trigger a DNS response containing a chunk of the HTTP response associated with token.

## Related Work

DNS tunneling as a topic of interest seems to have first appeared in 1998 [6]. Since it’s not a subject with much commercial value, and it’s far too tricky for your average hobbyist to successfully set up, there’s not much information about it on the Internet.
However, there are a decent number of blog and forum posts floating around, some with snippets of sample code. Most seem to have been written by security professionals interested in the possibility of a virus on an infected system using DNS tunneling to communicate with a C&C server under the radar, and how to defend against such a possibility.
Fortunately, even professionals guarding highly valuable systems don’t seem to have come up with any strategies for defeating DNS tunneling better than statistical analysis and drastic measures like blocking TXT-type DNS responses completely (which break systems that rely on them, like the SPF anti-spam protocol) [1][11].

DNS has traditionally run over the UDP protocol on port 53. However, when DNS responses are longer than 512 bytes the DNS system falls back to TCP. In the past this was fairly uncommon, so many DNS servers only supported UDP. Fortunately for us, the increasing popularity of DNSSEC and IPv6 means DNS packets longer than 512 bytes are becoming common. Our tunneling system will be much more reliable if we can force TCP to be used for the data transfer, so it’s convenient for us that the global DNS infrastructure has been motivated to ensure TCP is properly supported [2].

Our goal is to create an easy-to-use iOS app with a companion cloud service that allows basic web browsing through a DNS tunnel. Our stretch goal is to implement that functionality as an iOS Network Extension, allowing all apps and services on the system to be tunneled.

There are a significant number of existing projects that seek to provide semi-turnkey DNS tunneling capability. Unsurprisingly, most are designed to be operated on traditional x86 PC’s. Almost all require that users configure and operate their own server, something we identified as an insurmountable barrier to use by a realistic consumer. A few solutions are available for Android, some even with matching cloud services like we want to create [5]. However, no solutions exist for iOS as far as we know that don’t require jailbreaking the device.


- DNS2TCP seems to be one of the most robust solutions for tunneling arbitrary data over DNS. Developed by French security researchers. Last updated 2010. http://www.hsc.fr/ressources/outils/dns2tcp/ http://www.hsc.fr/ressources/outils/dns2tcp/download/README https://www.aldeid.com/wiki/Dns2tcp http://tools.kali.org/maintaining-access/dns2tcp
- There is a DNS2TCP package available for jailbroken iPhones. Last updated 2013. http://chug.org/blog/install-dns2tcp-on-ios/ http://planet-iphones.com/cydia/id/dns2tcp https://web.archive.org/web/20150816085011/ http://www.fosk.it/how-to-bypass-firewalls-or-captive-portals-with-dns2tcp.html
- Iodine is the most popular library for DNS tunneling. Open source. Last updated 2015. http://code.kryo.se/iodine/ https://github.com/yarrick/iodine
- There is an Iodine package available for jailbroken iPhones. Last updated 2013. http://blog.thireus.com/dns-tunneling-iodine-0-6-0-rc1-ios-version-ipv4-over-dns-tunnel-on-your-iphoneipadipod-touch
-  OzymanDNS are a client/server pair of simple Perl scripts for DNS tunneling together totaling less than 700 lines of code. Written by Dan Kaminsky for a conference in 2004. http://dankaminsky.com/2004/07/29/51/

We found a few existing applications that use the newly introduced network tunneling extension point. For example, iCepa uses the API to route all traffic system-wide through the Tor network [9]. On the app store, we found a few VPN apps that use the API to automatically install profiles (with user permission via a system dialog).

## Timeline/Milestones

We’ve compiled a list of milestones. They’re separated by client and server tasks, in roughly the order that they need to be completed. Milestones with the same number can be worked on in parallel, while milestones with higher numbers generally depend on earlier milestones.

We're targeting completion of the project by week 8 of term, so we should aim to average one client and one server milestone per week to stay on track.

#### Client
- *Milestone 0 - *Set up a test environment, specifically a wifi hotspot that blocks internet access other than DNS requests.
- *Milestone 1 - *Build an iOS app that logs all HTTP requests made through the in-app web browser.
- *Milestone 3 - *In app, make random DNS request to our server and verify correct “Hello world” response.
- *Milestone 4 - *Encode all outgoing HTTP requests as base64 and log them. Determine if it will be necessary to chunk HTTP requests.
- *Milestone 5* - Make initial DNS request to server with base64 encoded HTTP requests.
- *Milestone 7 - *Make continuing DNS request to server with token received in response to initial request. Repeat as necessary.
- *Milestone 9* - Reconstruct HTTP response data and return it to the in-app browser.
- get a working network extension where we successfully intercept all network traffic
#### Server
- *Milestone 0 - *Buy a domain and set up a server.
- *Milestone 1 - *Log incoming DNS requests.
- *Milestone 2 - *Reply with “Hello world” to all incoming DNS requests as a TXT record.
- *Milestone 3 - *Parse incoming DNS requests and classify as initial request or continuing request.
- *Milestone 6 - *Reply to all incoming initial requests with a randomly generated token and a number of chunks. Reply to all incoming continuing requests with “Hello {x}”, where x is a string associated with the token.
- *Milestone 7 - *Transmit incoming HTTP requests and store the response.
- *Milestone 8 - *Reply to continuing requests with data from the HTTP response.

If and when we receive the tunneling network extension entitlement from Apple, we’ll reevaluate our strategy and may decide to tunnel traffic at the network layer, rather than the application layer.

## Final Product

At the end of the term, we will have build an iPhone app that will provide no-setup DNS tunneling to its users. To do so, we must build both the app and the DNS server that user traffic will be passing through. Depending on if we receive the network extension entitlement, our app will either provide an in-app web browser (that tunnels only its traffic over DNS) or a 1-click button to configure the network extension (that tunnels all traffic system-wide over DNS).

#### Stretch Goals
- Determine how much it costs to tunnel the average users traffic. Then, use iOS’s in-app  purchase mechanism to allow users to subscribe to the service for a monthly fee. Perhaps also allow purchases of single-day passes.
- Provide a mechanism by which the user can test whether the app can connect over their current network without paying for a subscription or a pass. The app could simply try to connect to our server (over DNS) and show an indicator indicating success or failure. 
- Build an authentication mechanism so that our servers can only be used by paying users. Otherwise, we might build up a large bill that isn’t supported by user payments.
- Test our product in the real world to verify that it can bypass standard blocking systems. Additionally, form a list of blocking systems it can successfully bypass.
- Allow the user to set a custom server IP address instead of going through our server.
- Release an OS X app with similar capabilities. Since the network extension API is cross-platform, this would only require minimal effort.
- Make the service resilient to having our domain or IP address blocked. We could potentially accomplish this by changing the server’s IP address and domain every few weeks. We’d have to notify the device ahead of time of future planned domains and IP addresses so that a device unable to access our servers knows which to try next.
- Release the app on the App Store to get it in the hands of users.
#### Worst Case Scenario

If all goes as planned, we will have developed an app that enables system-wide DNS tunneling on a user’s device. We expect that Apple will likely approve our entitlement request, so we hope this will be the outcome. If Apple for some reason rejects our entitlement request, we’ll instead plan to build the in-app DNS tunneling browser.

If unexpected complications arise, we might face difficultly implementing our DNS tunneling protocol in a way that can interface with either UIWebView or NETunnelProvider. After spending a good amount of time researching the workings of each of these classes we believe this is unlikely, but we still ought to plan for such a situation. A backup plan could be to provide a more limited interface to the DNS tunnel—either a command line-like interface allow users to ping servers over DNS or perhaps a mechanism to download static HTML files and load them into the web view after the fact.

## Citations

[1] http://www.daemon.be/maarten/dnstunnel.html
[2] http://www.networkworld.com/article/2231682/cisco-subnet/cisco-subnet-allow-both-tcp-and-udp-port-53-to-your-dns-servers.html
[3] https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html#//apple_ref/doc/uid/10000165i
[4] https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURLProtocol_Class/index.html#//apple_ref/occ/cl/NSURLProtocol
[5] https://www.vpnoverdns.com/faq.html
[6] http://archives.neohapsis.com/archives/bugtraq/1998_2/0079.html
[7] https://developer.apple.com/library/prerelease/ios/documentation/NetworkExtension/Reference/NETunnelProviderClassRef/index.html
[8] https://developer.apple.com/videos/play/wwdc2015/717/
[9] https://github.com/iCepa/iCepa
[10] http://www.smartinsights.com/mobile-marketing/mobile-marketing-analytics/mobile-marketing-statistics/
[11] http://blog.cloudmark.com/2014/10/07/dns-tunneling-abuses/
[12] http://dnstunnel.de/
[13] http://www.splitbrain.org/blog/2008-11/02-dns_tunneling_made_simple

