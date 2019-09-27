using NServiceBus;
using System;

namespace messages
{
    public class HelloWorldMessage :IMessage
    {
        public string Content { get; set; }
    }
}
