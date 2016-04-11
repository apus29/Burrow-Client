//
//  ServerMessage.h
//  Burrow
//
//  Created by Jaden Geller on 4/11/16.
//
//

@import Foundation;
@import CResolver;
#import "ResourceRecord.h"

typedef ns_msg ServerMessage;
typedef ns_sect ServerMessageSection;

int ServerMessageGetCount(ServerMessage message, ServerMessageSection section);
int ServerMessageParse(ServerMessage message, ServerMessageSection section, int index, ResourceRecord *record);
int ServerMessageFromQuery(const char *domain, RecordClass class, RecordType type, u_char *answerBuffer, int bufferSize, ServerMessage *message);