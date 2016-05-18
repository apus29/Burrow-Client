//
//  ServerMessage.c
//  Burrow
//
//  Created by Jaden Geller on 4/11/16.
//
//

#include "ServerMessage.h"
extern res_state res_state_new();
extern void res_client_close(res_state res);

int ServerMessageGetCount(ServerMessage message, ServerMessageSection section) {
    return ns_msg_count(message, section);
}

int ServerMessageParse(ServerMessage message, ServerMessageSection section, int index, ResourceRecord *record) {
    if (ns_parserr(&message, section, index, record)) {
        return -1;
    }
    return 0;
}

int ServerMessageFromQuery(const char *domain, RecordClass class, RecordType type, bool useTCP, u_char *answerBuffer, int bufferSize, ServerMessage *message) {

    // TODO: Shared pool? One per dispatch queue w/ pool of queues? idk man....
    res_state statp = res_state_new();

    if (statp == NULL) {
        res_client_close(statp);
        return -1;
    }
    
    if (res_ninit(statp)) {
        res_client_close(statp);
        return -1;
    }
    
    if (useTCP) {
        // RES_USEVC uses virtual circuit. This forces usage of TCP.
        // Used in this way here: http://opensource.apple.com//source/libresolv/libresolv-60/res_init.c
        statp->options |= RES_USEVC;
    }
    else {
        // Unsetting the RES_USEVC flag makes it only use UDP
        statp->options &= ~RES_USEVC;
    }
    int answerLength = res_nquery(statp, domain, class, type, answerBuffer, bufferSize);
    res_client_close(statp);

    if (answerLength < 0) {
        return -1;
    }
    
    if (ns_initparse(answerBuffer, answerLength, message)) {
        return -1;
    }
    return 0;
}
