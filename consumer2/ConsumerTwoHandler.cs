using messages;
using NServiceBus;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace consumer2
{
    public class ConsumerTwoHandler : IHandleMessages<SpecialEvent>
    {
        public Task Handle(SpecialEvent message, IMessageHandlerContext context)
        {
            Console.WriteLine($"[!Event] Consumer Two Handler, Handling: {message.Content}");
            return Task.CompletedTask;
        }
    }
}
