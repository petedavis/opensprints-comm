// TODO:
// * deal with MAX_LINE better.
// * use more pointers to char instead of arrays of chars


#define MAX_LINE 20
#define MAX_COMMAND_CHARS 5
#define MAX_PAYLOAD_CHARS (MAX_LINE - MAX_COMMAND_CHARS)

char line[MAX_LINE + 1];

#define CHAR_MSG_INITIAL '!'
#define CHAR_PAYLOAD_SEPARATOR ':'

struct COMMAND_MSG
{
  int command;
  boolean hasPayload;
  char *payloadStr;
} receivedMsg;

enum
{
  RX_MSG_A,     // Handshake
  RX_MSG_C,     // Countdown seconds
  RX_MSG_G,     // Start race countdown, then race.
  RX_MSG_HW,    // request hw type and version
  RX_MSG_I,     // Flags for which sensors are active, 0 thru 31.
  RX_MSG_L,     // Number of ticks in a distance race
  RX_MSG_M,     // Toggle "mock mode" (fake race outputs)
  RX_MSG_S,     // Kill ongoing race
  RX_MSG_T,     // Number of seconds in a fixed-time race
  RX_MSG_P,     // Request protocol version
  RX_MSG_V,     // Request firmware version
  NUM_RX_COMMANDS,
};

char * rxMsgList[NUM_RX_COMMANDS]=
{
  "a",  // RX_MSG_A,
  "c",  // RX_MSG_C,
  "g",  // RX_MSG_G,
  "hw", // RX_MSG_HW,
  "i",  // RX_MSG_I,
  "l",  // RX_MSG_L,
  "m",  // RX_MSG_M,
  "s",  // RX_MSG_S,
  "t",  // RX_MSG_T,
  "p",  // RX_MSG_P,
  "v",  // RX_MSG_V,
};

boolean rxMsgExpectsPayload[NUM_RX_COMMANDS]=
{
  true,     // RX_MSG_A,
  true,     // RX_MSG_C,
  false,    // RX_MSG_G,
  false,    // RX_MSG_HW,
  true,     // RX_MSG_I,
  true,     // RX_MSG_L,
  false,    // RX_MSG_M,
  false,    // RX_MSG_S,
  true,     // RX_MSG_T,
  false,    // RX_MSG_P,
  false,    // RX_MSG_V,
};

enum
{
  TX_MSG_F,
  TX_MSG_A,
  TX_MSG_C,
  TX_MSG_CD,
  TX_MSG_G,
  TX_MSG_HW,
  TX_MSG_I,
  TX_MSG_L,
  TX_MSG_M,
  TX_MSG_S,
  TX_MSG_P,
  TX_MSG_V,
  TX_MSG_0,
  TX_MSG_1,
  TX_MSG_2,
  TX_MSG_3,
  TX_MSG_0F,
  TX_MSG_1F,
  TX_MSG_2F,
  TX_MSG_3F,
  TX_MSG_T,
  TX_MSG_NACK,
  TX_MSG_ERROR,
  NUM_TX_MSGS,
};

char * txMsgList[NUM_TX_MSGS]=
{
  "F",
  "A",
  "C",
  "CD",
  "G",
  "HW",
  "I",
  "L",
  "M",
  "S",
  "P",
  "V",
  "0",
  "1",
  "2",
  "3",
  "0f",
  "1f",
  "2f",
  "3f",
  "t",
  "NACK",
  "ERROR",
};

enum STATE
{
  STATE_IDLE,
  STATE_COUNTDOWN,
  STATE_RACING,
  NUM_STATES,
};

STATE currentState=STATE_IDLE;

//---------------------------

void blinkLed()
{
  switch(currentState)
  {
    case STATE_IDLE:
      break;
    case STATE_COUNTDOWN:
      break;
    case STATE_RACING:
      break;
  }
}

//---------------------------
// Serial Tx functions

void sendTxMsg(int msgCommand)
{
  switch(msgCommand)
  {
    case TX_MSG_F:
    case TX_MSG_A:
    case TX_MSG_C:
    case TX_MSG_CD:
    case TX_MSG_G:
    case TX_MSG_I:
    case TX_MSG_L:
    case TX_MSG_M:
    case TX_MSG_S:
    case TX_MSG_P:
    case TX_MSG_V:
    case TX_MSG_0:
    case TX_MSG_1:
    case TX_MSG_2:
    case TX_MSG_3:
    case TX_MSG_0F:
    case TX_MSG_1F:
    case TX_MSG_2F:
    case TX_MSG_3F:
    case TX_MSG_T:
    case TX_MSG_ERROR:
      break;
    case TX_MSG_NACK:
      Serial.println(txMsgList[TX_MSG_NACK]);
      break;
  }
}

//---------------------------
// Serial Rx functions

boolean lineAvailable(int max_line,char *line)
{
  int c;
  static int line_idx = 0;
  static boolean eol = false;
  if (max_line <= 0)    // handle bad values for max_line
  {
    eol = true;
    if (max_line == 0)
      line[0] = '\0';
  }
  else                // valid max_line
  {
    if (Serial.available() > 0)
    {
      c = Serial.read();
      if (c != -1)  // got a char -- should always be true
      {
        if (c == '\r' || c == '\n')
          eol = true;
        else
        {
          Serial.print(c,BYTE);
          line[line_idx++] = c;
        }
        if (line_idx >= max_line)
          eol = true;
        line[line_idx] = '\0';     // always terminate line, even if unfinished
      }
      if (eol)
      {
        line_idx = 0;           // reset for next line
        eol = false;               // get ready for another line
        return true;
      }
      else
        return false;
    }
  }
}

boolean isAlphaNum(char c)
{
  if(c >= '0' && c <= '9')
  {
    return true;
  }
  if(c >= 'a' && c <= 'z')
  {
    return true;
  }
  if(c >= 'A' && c <= 'Z')
  {
    return true;
  }
  return false;
}

// Check whether received message and payload are both valid
boolean isReceivedMsgValid(struct COMMAND_MSG testReceivedMsg)
{
  unsigned long int x;
  Serial.println("isReceivedMsgValid...");

  Serial.print("testReceivedMsg.command = ");
  Serial.print(testReceivedMsg.command,DEC);
  Serial.print(" = ");
  Serial.println(rxMsgList[testReceivedMsg.command]);

  Serial.print("\r\ntestReceivedMsg.hasPayload = ");
  Serial.println(testReceivedMsg.hasPayload,DEC);

  Serial.print("\r\ntestReceivedMsg.payloadStr = ");
  Serial.println(testReceivedMsg.payloadStr);

  if(testReceivedMsg.hasPayload)
  {
    // testReceivedMsg has payload, but isn't supposed to.
    if(!rxMsgExpectsPayload[testReceivedMsg.command])
    {
      Serial.println("testReceivedMsg has payload, but isn't supposed to.");
      return(false);
    }
    else
    {
      Serial.println("testReceivedMsg has payload and is supposed to.");
      // testReceivedMsg has payload and is supposed to.
      // check whether the payload value is correct.
      x = atol(testReceivedMsg.payloadStr);
      Serial.print("\r\n payload integer = ");
      Serial.println(x,DEC);
      Serial.println(x,HEX);
      switch(testReceivedMsg.command)
      {
        case RX_MSG_A:
          return(x >= 0 && x <= 65535);
          break;
        case RX_MSG_C:
          return(x >= 0 && x <= 127);
          break;
        case RX_MSG_I:
          // greater than zero and 32 bits or less.
          return(x > 0 && x <= 0xFFFFFFFF);
          break;
        case RX_MSG_L:
          return(x >= 0 && x <= 65535);
          break;
        case RX_MSG_T:
          return(x >= 0 && x <= 65535);
          break;
        default:
          Serial.println("FART!!!");
          return(false);
          break;
      }
    }
  }
  else  // (!testReceivedMsg.hasPayload)
  {
    // testReceivedMsg doesn't have payload, but is supposed to.
    if(rxMsgExpectsPayload[testReceivedMsg.command])
    {
      Serial.println("testReceivedMsg doesn't have payload, but is supposed to.");
      return(false);
    }
    else
    {
      // testReceivedMsg doesn't have payload, and isn't supposed to.
      Serial.println("testReceivedMsg doesn't have payload, and isn't supposed to.");
      return(true);
    }
  }
}

// Check for a new valid message from the serial port.
// If one exists, update receivedMsg and return true.
// Otherwise, return false.
boolean newMsgReceived()
{
  struct COMMAND_MSG tempReceivedMsg;
  char tempCommandString[MAX_COMMAND_CHARS];
  char tempPayloadString[MAX_PAYLOAD_CHARS];
  unsigned int lineIdx;      // Used to index through string contained in "line".
  unsigned int linePartIdx;  // Used to index through "tempCommandString" and "tempPayloadString" .
  int i;

  if(lineAvailable(MAX_LINE,line))
  {
    Serial.print("\r\nreceived: ");
    Serial.print(line);       // echo back the line we just read
    Serial.println();
    if(line[0]!=CHAR_MSG_INITIAL)
    {
      sendTxMsg(TX_MSG_NACK);
      return(false);
    }
    else // line[0]==CHAR_MSG_INITIAL
    {
      lineIdx = 0;
      lineIdx++; // 1st char in line is CHAR_MSG_INITIAL
      linePartIdx = 0;
      // Extract the ID of the command in the message.
      while(isAlphaNum(line[lineIdx]))
      {
        if(linePartIdx <= MAX_COMMAND_CHARS) 
        {
          tempCommandString[linePartIdx]=line[lineIdx];
          lineIdx++;
          linePartIdx++;
        }
        else
        {
          Serial.println("message string is too long.");
          sendTxMsg(TX_MSG_NACK);
          return(false);
        }
      }
      tempCommandString[linePartIdx]='\0';
      // Check whether tempCommandString is filled with at least one character.
      if(linePartIdx == 0)
      {
        sendTxMsg(TX_MSG_NACK);
        return(false);
      }
      // tempCommandString is filled with at least one character
      // so continue processing.
      // Check for a bad character next in the string
      if(!(line[lineIdx] == '\0' || line[lineIdx] == CHAR_PAYLOAD_SEPARATOR))
      {
        sendTxMsg(TX_MSG_NACK);
        return(false);
      }
      // Not a bad character, so continue processing.
      i = 0;
      while(i < NUM_RX_COMMANDS)
      {
        if(strcmp(tempCommandString,rxMsgList[i])==0)
        {
          Serial.println("a match.");
          tempReceivedMsg.command=i;
          // Extract message payload
          if(line[lineIdx]=='\0')
          {
            tempReceivedMsg.hasPayload=false;
            tempReceivedMsg.payloadStr[0]='\0';
            if(isReceivedMsgValid(tempReceivedMsg))
            {
              receivedMsg=tempReceivedMsg;
              return(true);
            }
            else
            {
              sendTxMsg(TX_MSG_NACK);
              return(false);
            }
          }
          else // line[lineIdx]==CHAR_PAYLOAD_SEPARATOR
          {
            tempReceivedMsg.hasPayload=true;
            lineIdx++;
            linePartIdx = 0;
            while(isAlphaNum(line[lineIdx]))
            {
              if(linePartIdx <= MAX_PAYLOAD_CHARS)
              {
                tempPayloadString[linePartIdx]=line[lineIdx];
                lineIdx++;
                linePartIdx++;
              }
              else
              {
                Serial.println("payload string is too long.");
                sendTxMsg(TX_MSG_NACK);
                return(false);
              }
            }
            tempPayloadString[linePartIdx]='\0';
            // first non-alpha-numeric character
            // should be '\0'
            if(!(line[lineIdx]=='\0'))
            {
              Serial.println("some junk characters in payload string.");
              sendTxMsg(TX_MSG_NACK);
              return(false);
            }
            // Payload should have more than zero characters.
            if(linePartIdx == 0)
            {
              Serial.println("Zero characters in payload string.");
              sendTxMsg(TX_MSG_NACK);
              return(false);
            }
            // check the payload
            tempReceivedMsg.payloadStr = tempPayloadString;
            if(isReceivedMsgValid(tempReceivedMsg))
            {
              receivedMsg=tempReceivedMsg;
              return(true);
            }
            else
            {
              sendTxMsg(TX_MSG_NACK);
              return(false);
            }
          }
          break;
        }
        if(++i == NUM_RX_COMMANDS)
        {
          // No message matches. 
          sendTxMsg(TX_MSG_NACK);
          return(false);
        }
      }
    }
  }
  // new message not received.
  return(false);
}

//---------------------------

void doStateIdle()
{
  if(newMsgReceived())
  {
    Serial.print("new message: ");
    Serial.println(rxMsgList[receivedMsg.command]);
  }
  else
  {
  }
}

void doStateCountdown()
{
  if(newMsgReceived())
  {
  }
  else
  {
  }
}

void doStateRacing()
{
  if(newMsgReceived())
  {
  }
  else
  {
  }
}

void setup()
{
  Serial.begin(115200); 
}

void loop()
{
  blinkLed();
  switch(currentState)
  {
    case STATE_IDLE:
      doStateIdle();
      break;
    case STATE_COUNTDOWN:
      doStateCountdown();
      break;
    case STATE_RACING:
      doStateRacing();
      break;
    default:
      break;
  }
}
