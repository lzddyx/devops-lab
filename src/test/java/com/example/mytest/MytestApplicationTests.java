package com.example.mytest;
import java.net.URI;
import java.net.http.*;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import static org.junit.jupiter.api.Assertions.*;
@SpringBootTest(webEnvironment=SpringBootTest.WebEnvironment.RANDOM_PORT, properties="server.address=127.0.0.1")
class MytestApplicationTests {
    @Value("${local.server.port}") private int port;
    private HttpResponse<String> get(String path) throws Exception {
        try (HttpClient client=HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build()) {
            return client.send(HttpRequest.newBuilder(URI.create("http://127.0.0.1:"+port+path)).timeout(Duration.ofSeconds(5)).GET().build(), HttpResponse.BodyHandlers.ofString());
        }
    }
    @Test void testEndpoint() throws Exception {
        var response=get("/test");
        assertEquals(200,response.statusCode());
        assertEquals("Hello Jenkins!",response.body());
        assertTrue(response.headers().firstValue("content-type").orElse("").startsWith("text/plain"));
    }
    @Test void healthEndpoint() throws Exception {
        var response=get("/health");
        assertEquals(200,response.statusCode()); assertEquals("OK",response.body());
    }
    @Test void unknownEndpoint() throws Exception { assertEquals(404,get("/missing").statusCode()); }
}
