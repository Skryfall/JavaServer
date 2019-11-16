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

    /**
     * Metodo que recibe los datos de los juegos del cliente en python
     * @param jsonHolder json con los datos del juego
     * @throws JsonProcessingException
     */
    @POST
    public void receiveGameData(String jsonHolder) throws JsonProcessingException {
        Handler.deserializeGameData(jsonHolder);
        System.out.println("Recibido");
    }

    /**
     * Metodo que envia los datos de los juegos al cliente en swift
     * @return holder serializado a json con los datos
     */
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Holder sendGameData(){
        System.out.println("Enviado");
        return Handler.holder;
    }

}
