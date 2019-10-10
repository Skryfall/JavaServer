package server;

import javax.ws.rs.GET;
import javax.ws.rs.Path;

@Path("Test")
public class Test {

    @GET
    public void foo(){
        System.out.println("HOLA");
        return;
    }

}
