using NServiceBus;
using System;
using System.Collections.Generic;
using System.Text;

namespace messages
{
    public class SpecialEvent :IEvent
    {
        public string Content { get; set; }
    }
}
