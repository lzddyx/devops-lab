package com.example.mytest;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
@RestController
public class TestController {
    @GetMapping(value="/test", produces=MediaType.TEXT_PLAIN_VALUE)
    public String test() { return "Hello Jenkins!"; }
    @GetMapping(value="/health", produces=MediaType.TEXT_PLAIN_VALUE)
    public String health() { return "OK"; }
}
