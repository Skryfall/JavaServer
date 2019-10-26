package server;

import com.fasterxml.jackson.core.JsonProcessingException;
import data.Handler;
import data.Holder;

import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

@Path("GameData")
public class GameDataHandler {

    @POST
    public void receiveGameData(String jsonHolder) throws JsonProcessingException {
        Handler.deserializeGameData(jsonHolder);
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Holder sendGameData(){
        return Handler.holder;
    }

}
