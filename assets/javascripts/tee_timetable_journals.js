$(document).ready(function(){

	// Detectamos si el dia de la semana es laboral o no laboral.
	$('.workable').on('click', function(){
		num = $(this).attr('id');
		if($(this).is(':checked')){
			// Activamos los selects de las horas de esa semana.
			for(var i=1; i<=5; i++){
				$("#tee_timetable_journals_attributes_"+num+"_start_time_"+i.toString()+"i").attr("disabled",false);
				$("#tee_timetable_journals_attributes_"+num+"_end_time_"+i.toString()+"i").attr("disabled",false);
			}
			
		} else {
			// Desactivamos los selects de las horas de esa semana
			for(var i=1; i<=5; i++){
				$("#tee_timetable_journals_attributes_"+num+"_start_time_"+i.toString()+"i").attr("disabled",true);
				$("#tee_timetable_journals_attributes_"+num+"_end_time_"+i.toString()+"i").attr("disabled",true);
			}

			$("#tee_timetable_journals_attributes_"+num+"_start_time_4i option:eq(0)").prop('selected',true);
			$("#tee_timetable_journals_attributes_"+num+"_start_time_5i option:eq(0)").prop('selected',true);
			$("#tee_timetable_journals_attributes_"+num+"_end_time_4i option:eq(0)").prop('selected',true);
			$("#tee_timetable_journals_attributes_"+num+"_end_time_5i option:eq(0)").prop('selected',true);
		}
	});

	// Si dicho horario es establecido como 'por defecto' se desactiva los inputs de 'Fecha de inicio' y 'Fecha de fin'.
	// En caso contrario se activaran dichos inputs donde se introduciran los rangos de fechas para ese horario.
	$('.timetable_default').on('click', function(){
		if($(this).is(':checked')){
			disabledTimetableDates();
			$("#tee_timetable_start_date").prop("value",null);
			$("#tee_timetable_end_date").prop("value",null);
		} else {
			$("#tee_timetable_start_date").attr("disabled",false);
			$("#tee_timetable_end_date").attr("disabled",false);
		}
	});

	$(".timetable.timetable_form").ready(function() {
		if($('.timetable_default').is(':checked')){
			disabledTimetableDates();
		}

	});	

	function disabledTimetableDates(){
		$("#tee_timetable_start_date").attr("disabled",true);
		$("#tee_timetable_end_date").attr("disabled",true);
	}
});