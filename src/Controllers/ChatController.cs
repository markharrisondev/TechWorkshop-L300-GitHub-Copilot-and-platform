using Microsoft.AspNetCore.Mvc;
using Azure.AI.OpenAI;
using Azure;
using Azure.Identity;
using OpenAI.Chat;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly ILogger<ChatController> _logger;
        private readonly IConfiguration _configuration;

        public ChatController(ILogger<ChatController> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SendMessage([FromBody] ChatRequest request)
        {
            _logger.LogInformation("SendMessage called with message: {Message}", request.Message);
            
            try
            {
                var endpoint = _configuration["AZURE_FOUNDRY_ENDPOINT"];
                _logger.LogInformation("AZURE_FOUNDRY_ENDPOINT: {Endpoint}", endpoint ?? "null");
                
                var modelName = "Phi-4";

                if (string.IsNullOrEmpty(endpoint))
                {
                    _logger.LogWarning("Azure Foundry endpoint not configured");
                    return BadRequest(new { error = "Azure Foundry endpoint not configured" });
                }

                var credential = new DefaultAzureCredential();
                var client = new AzureOpenAIClient(new Uri(endpoint), credential);
                var chatClient = client.GetChatClient(modelName);

                var messages = new List<ChatMessage>
                {
                    new SystemChatMessage("You are a helpful assistant for the Zava Storefront. Help customers with product information and general inquiries."),
                    new UserChatMessage(request.Message)
                };

                var chatOptions = new ChatCompletionOptions
                {
                    MaxOutputTokenCount = 500,
                    Temperature = 0.7f
                };

                var response = await chatClient.CompleteChatAsync(messages, chatOptions);
                var responseMessage = response.Value.Content[0].Text;

                _logger.LogInformation("Chat message processed successfully. Response: {Response}", responseMessage);

                return Json(new { response = responseMessage });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing chat message");
                return StatusCode(500, new { error = "An error occurred while processing your message" });
            }
        }
    }

    public class ChatRequest
    {
        public string Message { get; set; } = string.Empty;
    }
}
