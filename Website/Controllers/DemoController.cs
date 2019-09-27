using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using messages;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using NServiceBus;

namespace Website.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DemoController : ControllerBase
    {
        private readonly IMessageSession endpoint;

        public DemoController(IMessageSession endpoint)
        {
            this.endpoint = endpoint;
        }
        [Route("helloworld")]
        [HttpPost]
        public async Task HelloWorld([FromQuery]string message)
        {
            await endpoint.Send<HelloWorldMessage>(msg => { msg.Content = message; });
        }
        [Route("helloworldpublish")]
        [HttpPost]
        public async Task HelloWorld2([FromQuery]string message)
        {
            await endpoint.Publish<SpecialEvent>(msg => { msg.Content = message; });
        }
    }
}