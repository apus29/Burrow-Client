//
//  ServerMessage.c
//  Burrow
//
//  Created by Jaden Geller on 4/11/16.
//
//

#include "ServerMessage.h"

int ServerMessageGetCount(ServerMessage message, ServerMessageSection section) {
    return ns_msg_count(message, section);
}

int ServerMessageParse(ServerMessage message, ServerMessageSection section, int index, ResourceRecord *record) {
    if (ns_parserr(&message, section, index, record)) {
        return -1;
    }
    return 0;
}

int ServerMessageFromQuery(const char *domain, RecordClass class, RecordType type, u_char *answerBuffer, int bufferSize, ServerMessage *message) {
    int answerLength;
    if((answerLength = res_query(domain, class, type, answerBuffer, bufferSize)) < 0) {
        return -1;
    }
    if (ns_initparse(answerBuffer, answerLength, message)) {
        return -1;
    }
    return 0;
}
