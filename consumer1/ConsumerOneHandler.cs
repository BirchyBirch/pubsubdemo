using messages;
using NServiceBus;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace consumer1
{
    public class ConsumerOneHandler : IHandleMessages<HelloWorldMessage>, IHandleMessages<SpecialEvent>
    {
        public Task Handle(HelloWorldMessage message, IMessageHandlerContext context)
        {
            Console.WriteLine($"Consumer One Handler, Handling: {message.Content}");
            return Task.CompletedTask;
        }

        public Task Handle(SpecialEvent message, IMessageHandlerContext context)
        {
            Console.WriteLine($"[!Event] Consumer One Handler, Handling: {message.Content}");
            return Task.CompletedTask;
        }
    }
}
