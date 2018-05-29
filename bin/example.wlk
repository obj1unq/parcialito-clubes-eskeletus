class Socio{
	var property club
	var property antiguedad
	var property actividadesSocialesParticipadas
	method esEstrella() = self.antiguedad() == 20
	method esDestacado() = self.club().actividadesSociales().find({_actividad => _actividad.organizador() == self})
}

class Jugador inherits Socio{
	var property partidosJugados
	var property valorDePase
	override method esEstrella() = self.partidosJugados() >= 50 || self.club().requisitoParaEstrella(self)
	override method esDestacado() = super() || self.club().equipos().find({_equipo => _equipo.capitan() == self})
	method haceteDeAbajo(){ //a.k.a reset por transferencia
		partidosJugados = 0
	}
}

class Club{
	var socios = #{}
	var property gastoMensual
	var clubSancionado = false
	var property actividadesSociales = #{}
	var property equipos = #{}
	method agregarSocio(socio){
		socios.add(socio)
	}
	method requisitoParaEstrella(jugador)
	method sancionarClub(){
		if(socios.size()>500){
			clubSancionado = true 
			actividadesSociales=actividadesSociales.map({ _actividad => self.sancionarActividad(_actividad)}).asSet()
			equipos=equipos.map({_equipo => self.sancionarActividad(_equipo)}).asSet()
		}
	}
	method reanudarClub(){
		clubSancionado = false 
		actividadesSociales=self.actividadesSociales().map({ _actividad => self.reanudarActividad(_actividad)}).asSet()
	}
	method sancionarActividad(actividad){
		actividad.sancionar()
	}
	method reanudarActividad(actividad){
		actividad.reanudar()
	}
	method actividadSuspendida(actividad) = actividad.sancionada()
	method evaluarActividad(actividad) = actividad.evaluacion()
	method evaluacionClub() = self.evaluacionBruta()/socios.size()
	method evaluacionBruta()
	method obtenerDestacados() = socios.filter({_socio => _socio.esDestacado()})
	method obtenerDestacadosyEstrella() = self.obtenerDestacados().filter({_socio => _socio.esEstrella()})
	method esPrestigioso() = self.equipos().any({_equipo => _equipo.esExperimentado()}) || self.actividadesSociales().any({_actividad=>_actividad.estrellas()>=5})
	method transferir(jugador, equipo, otroClub){
		//Asumiendo que otroClub es el club del equipo a transferir el jugador
		if (not (jugador.esDestacado() || self.equipos().contains(equipo))){
			equipos = self.equipos().map({_equipo => if(_equipo.plantel().contains(jugador)) _equipo.echar(jugador)}).asSet()
			actividadesSociales = self.actividadesSociales().map({_actividad => if(_actividad.sociosParticipantes().contains(jugador)) _equipo.remove(jugador)}).asSet()
			socios.remove(jugador)
			otroClub.equipos().map({_equipo => if(_equipo==equipo)_equipo.add(jugador)})
			otroClub.agregarSocio(jugador)
			
		}
	}
}

class ClubProfesional inherits ClubComunitario{
	override method requisitoParaEstrella(jugador){
		jugador.valorDePase() > valoresConfigurables.valorPase1() //valorConfigurableDelSistema
	}
	override method evaluacionBruta() = super()-self.gastoMensual()
}

class ClubComunitario inherits Club{
	override method requisitoParaEstrella(jugador){
		(jugador.partidosJugados()+jugador.actividadesSocialesParticipadas()) >= 3
	}
	override method evaluacionBruta() = equipos.sum({_equipo => self.evaluarActividad(_equipo)})+actividadesSociales.sum({_actividades => self.evaluarActividad(_actividades)})
}

class ClubTradicional inherits ClubComunitario{
	override method requisitoParaEstrella(jugador){
		super(jugador) || jugador.valorDePase() > valoresConfigurables.valorPase1()
	}
	override method evaluacionBruta() = super()*2-self.gastoMensual()*5
}

class ActividadSocial{
	var property sancionada = false
	var valorDeEvaluacion
	var property organizador
	var property sociosParticipantes = #{}
	method sancionar(){
		sancionada = true
	}
	method reanudar(){
		sancionada = false
	}
	method estrellas() = self.sociosParticipantes().size().filter({_socio => _socio.esEstrella()})
	method evaluacion() = if(self.sancionada()) 0 else valorDeEvaluacion
}

class Equipo{
	var property sanciones = 0
	var campeonatosGanados = 0
	var property capitan
	var equipo = #{capitan}
	method agregarAlEquipo(jugador){
		equipo.add(jugador)
	}
	method sancionar(){
		sanciones += 1
	}
	method echar(jugador){
		equipo.remove(jugador)
	}
	method evaluacion() = 5 * campeonatosGanados + equipo.size() * 2 + if (capitan.esEstrella()) 5 else 0 - 20 * self.sanciones()
	method experimentado() = equipo.all({_jugador => _jugador.partidosJugados()>=10})
}

class EquipoDeFutbol inherits Equipo{
	override method evaluacion() = super() + 5 * equipo.size(equipo.filter({_jugador => _jugador.esEstrella()})) - 10 * self.sanciones()
}

object valoresConfigurables{
	method valorPase1() = 10000
	method valorActividad1() = 15
	method valorActividad2() = 20
	method valorClub1() = 20000
}